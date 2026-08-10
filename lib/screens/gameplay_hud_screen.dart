import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../audio/audio_manager.dart';
import '../game/aim_fire_controller.dart';
import '../game/game_loop.dart';
import '../game/game_state.dart';
import '../game/leveling.dart';
import '../game/player_controller.dart';
import '../prefs/app_flags.dart';
import '../state/economy_state.dart';
import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import 'game_over_screen.dart';
import 'how_to_play_overlay.dart';
import 'pause_overlay.dart';
import 'win_screen.dart';

/// Gameplay HUD shell — visual presentation + wired match loop.
class GameplayHudScreen extends StatefulWidget {
  const GameplayHudScreen({super.key, this.hollowDepth = 5});

  final int hollowDepth;

  @override
  State<GameplayHudScreen> createState() => _GameplayHudScreenState();
}

class _GameplayHudScreenState extends State<GameplayHudScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  static const int _hpSegments = 6;

  late final AnimationController _damagedFlashController;
  late final AnimationController _pickupController;
  late final AnimationController _vignetteController;
  late final AnimationController _levelUpController;

  late final Animation<double> _damagedFlash;
  late final Animation<double> _pickupScale;
  late final Animation<double> _pickupOpacity;
  late final Animation<double> _vignetteOpacity;
  late final Animation<double> _levelUpOpacity;
  late final Animation<double> _levelUpScale;

  late final GameState _gameState;
  late final GameLoop _loop;

  bool _sessionReady = false;
  bool _showPickup = false;
  bool _showLevelUp = false;
  bool _showTutorial = false;
  bool _persistTutorialFlag = false;
  String? _lastPickupSeen;
  bool _ending = false;

  /// Loaded top-down sheets for the equipped character (idle/walk × facing).
  _PlayerSpriteSet? _playerSprites;
  _EnemySpriteAtlas? _enemySprites;
  Map<String, ui.Image>? _envSprites;
  ui.Image? _xpOrbSprite;
  ui.Image? _magnetSprite;

  PlayerController get _player => _loop.player;
  AimFireController get _aim => _loop.aim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // Damaged HP segment idle flash.
    _damagedFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _damagedFlash = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _damagedFlashController, curve: Curves.easeInOut),
    );

    // Pickup toast: scale + fade.
    _pickupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _pickupScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.6, end: 1.1)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.1, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.4,
      ),
      TweenSequenceItem(
        tween: ConstantTween(1.0),
        weight: 1.2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.9)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 0.6,
      ),
    ]).animate(_pickupController);
    _pickupOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1),
    ]).animate(_pickupController);
    _pickupController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() => _showPickup = false);
      }
    });

    // Damage vignette pulse.
    _vignetteController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _vignetteOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.85), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.85, end: 0.0), weight: 2.2),
    ]).animate(
      CurvedAnimation(parent: _vignetteController, curve: Curves.easeOut),
    );

    // Level-up overlay.
    _levelUpController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _levelUpOpacity = CurvedAnimation(
      parent: _levelUpController,
      curve: Curves.easeOut,
    );
    _levelUpScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _levelUpController, curve: Curves.easeOutBack),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionReady) return;
    _sessionReady = true;

    final economy = context.read<EconomyState>();
    final characterId = economy.equippedCharacterId ?? 'wanderer';
    _gameState = GameState(
      hollowDepth: widget.hollowDepth,
      playerCharacterId: characterId,
      startingMaxHp: 100 + economy.talentLevel('maxhp') * 8,
      startingMoveSpeed: 175 + economy.talentLevel('speed') * 10.0,
      startingDamage: 12 + economy.talentLevel('damage') * 2.0,
      startingFireCooldown: 0.38,
    );
    _gameState.addListener(_onGameStateChanged);

    _loop = GameLoop(
      state: _gameState,
      vsync: this,
      onPlayerDamaged: _triggerDamage,
      onLevelUp: _openLevelUp,
      onEnded: _handleRunEnded,
    );

    _loadPlayerSprites(characterId);
    _loadEnemySprites();
    _loadEnvSprites();
    _loadPickupSprites();

    _maybeShowFirstMatchTutorial().then((_) {
      if (mounted) _loop.start();
    });
  }

  Future<void> _loadPlayerSprites(String characterId) async {
    try {
      final set = await _PlayerSpriteSet.load(characterId);
      if (!mounted) {
        set.dispose();
        return;
      }
      _playerSprites?.dispose();
      setState(() => _playerSprites = set);
    } catch (e) {
      debugPrint('Player sprites failed to load for $characterId: $e');
    }
  }

  Future<void> _loadEnemySprites() async {
    try {
      final atlas = await _EnemySpriteAtlas.load();
      if (!mounted) {
        atlas.dispose();
        return;
      }
      _enemySprites?.dispose();
      setState(() => _enemySprites = atlas);
    } catch (e) {
      debugPrint('Enemy sprites failed to load: $e');
    }
  }

  Future<void> _loadEnvSprites() async {
    try {
      final map = <String, ui.Image>{};
      for (final path in AppAssets.gameObstacleAssets) {
        map[path] = await _loadUiImage(path);
      }
      if (!mounted) {
        for (final img in map.values) {
          img.dispose();
        }
        return;
      }
      final old = _envSprites;
      setState(() => _envSprites = map);
      if (old != null) {
        for (final img in old.values) {
          img.dispose();
        }
      }
    } catch (e) {
      debugPrint('Environment sprites failed to load: $e');
    }
  }

  Future<void> _loadPickupSprites() async {
    try {
      final xp = await _loadUiImage(AppAssets.gameXpOrb);
      final magnet = await _loadUiImage(AppAssets.gameMagnet);
      if (!mounted) {
        xp.dispose();
        magnet.dispose();
        return;
      }
      _xpOrbSprite?.dispose();
      _magnetSprite?.dispose();
      setState(() {
        _xpOrbSprite = xp;
        _magnetSprite = magnet;
      });
    } catch (e) {
      debugPrint('Pickup sprites failed to load: $e');
    }
  }

  @override
  void dispose() {
    if (_sessionReady) {
      _gameState.removeListener(_onGameStateChanged);
      _loop.dispose();
      _gameState.dispose();
    }
    _playerSprites?.dispose();
    _enemySprites?.dispose();
    if (_envSprites != null) {
      for (final img in _envSprites!.values) {
        img.dispose();
      }
    }
    _xpOrbSprite?.dispose();
    _magnetSprite?.dispose();
    _damagedFlashController.dispose();
    _pickupController.dispose();
    _vignetteController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  void _onGameStateChanged() {
    final label = _gameState.lastPickupLabel;
    if (label != null && label != _lastPickupSeen) {
      _lastPickupSeen = label;
      _triggerPickup();
    }
  }

  Future<void> _maybeShowFirstMatchTutorial() async {
    final seen = await AppFlags.hasSeenTutorial();
    if (!mounted) return;
    if (!seen) {
      _gameState.setPaused(true);
      AudioManager.instance.pauseMusic();
      setState(() {
        _showTutorial = true;
        _persistTutorialFlag = true;
      });
    }
  }

  void _triggerPickup() {
    if (!mounted) return;
    setState(() => _showPickup = true);
    _pickupController.forward(from: 0);
  }

  void _triggerDamage() {
    if (!mounted) return;
    _vignetteController.forward(from: 0);
  }

  Future<void> _openLevelUp() async {
    if (!mounted || _showLevelUp) return;
    AudioManager.instance.playLevelUp();
    AudioManager.instance.pauseMusic();
    setState(() => _showLevelUp = true);
    await _levelUpController.forward(from: 0);
  }

  Future<void> _closeLevelUp() async {
    await _levelUpController.reverse();
    if (mounted) {
      setState(() => _showLevelUp = false);
      if (!_gameState.isPaused) {
        AudioManager.instance.resumeMusic();
      }
    }
  }

  void _chooseUpgrade(LevelUpUpgrade upgrade) {
    AudioManager.instance.playTap();
    Leveling.apply(_gameState, upgrade);
    _closeLevelUp();
  }

  void _skipLevelUp() {
    AudioManager.instance.playTap();
    _gameState.completeLevelUp();
    _closeLevelUp();
  }

  void _setPaused(bool value) {
    _gameState.setPaused(value);
    if (value) {
      AudioManager.instance.pauseMusic();
    } else if (!_gameState.awaitingLevelUp) {
      AudioManager.instance.resumeMusic();
    }
    setState(() {});
  }

  void _restartRun() {
    _loop.stop();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            GameplayHudScreen(hollowDepth: widget.hollowDepth),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _quitToMenu() {
    _loop.stop();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _handleRunEnded({
    required bool won,
    required int killCount,
    required String timeLabel,
    required int embersEarned,
  }) {
    if (!mounted || _ending) return;
    _ending = true;
    context.read<EconomyState>().addEmbers(embersEarned);

    final screen = won
        ? WinScreen(
            enemiesDefeated: killCount,
            timeSurvived: timeLabel,
            embersEarned: embersEarned,
          )
        : GameOverScreen(
            enemiesDefeated: killCount,
            timeSurvived: timeLabel,
            embersEarned: embersEarned,
          );

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady) {
      return const Scaffold(
        backgroundColor: _charcoal,
        body: SizedBox.expand(),
      );
    }

    return ChangeNotifierProvider<GameState>.value(
      value: _gameState,
      child: Scaffold(
        backgroundColor: _charcoal,
        body: ListenableBuilder(
          listenable: _gameState,
          builder: (context, _) {
            return Stack(
              fit: StackFit.expand,
              children: [
                const FieldBackdrop(showField: true, fogOpacity: 0.14),
                // Soft ambient vignette (always on, subtle).
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.45, 0.8, 1.0],
                      ),
                    ),
                  ),
                ),

                // Playfield entities.
                LayoutBuilder(
                  builder: (context, constraints) {
                    final size =
                        Size(constraints.maxWidth, constraints.maxHeight);
                    if (size != _gameState.worldSize) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) _gameState.setWorldSize(size);
                      });
                    }
                    return CustomPaint(
                      painter: _ArenaPainter(
                        state: _gameState,
                        playerSprites: _playerSprites,
                        enemySprites: _enemySprites,
                        envSprites: _envSprites,
                        xpOrbSprite: _xpOrbSprite,
                        magnetSprite: _magnetSprite,
                        aimRangeAlpha: _aim.rangeIndicatorAlpha,
                        aimRangeRadius: AimFireController.rangeIndicatorRadius,
                      ),
                      size: size,
                    );
                  },
                ),

                // HUD chrome.
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                    child: Builder(
                      builder: (context) {
                        final hpRatio = _gameState.maxHp <= 0
                            ? 0.0
                            : (_gameState.playerHp / _gameState.maxHp)
                                .clamp(0.0, 1.0);
                        final damagedIndex = _gameState.playerHp <= 0
                            ? -1
                            : math.max(
                                0,
                                (hpRatio * _hpSegments).ceil() - 1,
                              );

                        return Stack(
                          children: [
                            // Top-left HP.
                            Align(
                              alignment: Alignment.topLeft,
                              child: _HpBar(
                                segments: _hpSegments,
                                damagedIndex: damagedIndex,
                                flash: _damagedFlash,
                                controller: _damagedFlashController,
                              ),
                            ),

                            // Top-right timer + pause.
                            Align(
                              alignment: Alignment.topRight,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _gameState.timerLabel,
                                    style: TextStyle(
                                      fontFamily: 'monospace',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 2,
                                      color:
                                          Colors.white.withValues(alpha: 0.88),
                                      shadows: [
                                        Shadow(
                                          color: _maroon.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  GestureDetector(
                                    onTap: () => _setPaused(true),
                                    behavior: HitTestBehavior.opaque,
                                    child: Image.asset(
                                      AppAssets.iconPause,
                                      width: 28,
                                      height: 28,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Center-top pickup notification.
                            if (_showPickup)
                              Align(
                                alignment: const Alignment(0, -0.72),
                                child: AnimatedBuilder(
                                  animation: _pickupController,
                                  builder: (context, child) {
                                    return Opacity(
                                      opacity: _pickupOpacity.value,
                                      child: Transform.scale(
                                        scale: _pickupScale.value,
                                        child: child,
                                      ),
                                    );
                                  },
                                  child: _PickupToast(
                                    text:
                                        _gameState.lastPickupLabel ?? '+XP',
                                  ),
                                ),
                              ),

                            // Magnet active indicator (pickup-toast style).
                            if (_gameState.magnetActive)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: _PickupToast(
                                    text:
                                        'MAGNET ${_gameState.magnetTimeLeft.ceil()}s',
                                    leading: Image.asset(
                                      AppAssets.gameMagnet,
                                      width: 18,
                                      height: 18,
                                      filterQuality: FilterQuality.none,
                                    ),
                                  ),
                                ),
                              ),

                            // Bottom-left joystick.
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(left: 8, bottom: 8),
                                child: _CircleControl(
                                  outerSize: 118,
                                  innerSize: 48,
                                  knuckle:
                                      _player.knuckleOffset((118 - 48) / 2),
                                  onPanStart: (delta) {
                                    _player.setStickFromLocalDelta(delta, 59);
                                    setState(() {});
                                  },
                                  onPanUpdate: (delta) {
                                    _player.setStickFromLocalDelta(delta, 59);
                                    setState(() {});
                                  },
                                  onPanEnd: () {
                                    _player.clearStick();
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),

                            // Bottom-right shoot/aim + ammo readout.
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding:
                                    const EdgeInsets.only(right: 8, bottom: 8),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    Text(
                                      '${_gameState.currentAmmo.toString().padLeft(3, '0')}/${_gameState.maxAmmo.toString().padLeft(3, '0')}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                        color: _gameState.isReloading
                                            ? Colors.white
                                                .withValues(alpha: 0.45)
                                            : Colors.white
                                                .withValues(alpha: 0.88),
                                        shadows: [
                                          Shadow(
                                            color: _maroon.withValues(
                                              alpha: 0.55,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_gameState.isReloading)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          'Reloading...',
                                          style: TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 10,
                                            letterSpacing: 0.5,
                                            color: const Color(0xFFE8C547)
                                                .withValues(alpha: 0.9),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(height: 6),
                                    _CircleControl(
                                      outerSize: 96,
                                      innerSize: 52,
                                      label: 'AIM',
                                      knuckle:
                                          _aim.knuckleOffset((96 - 52) / 2),
                                      onPanStart: (delta) {
                                        _aim.onPanStart(delta, 48);
                                        setState(() {});
                                      },
                                      onPanUpdate: (delta) {
                                        _aim.onPanUpdate(delta, 48);
                                        setState(() {});
                                      },
                                      onPanEnd: () {
                                        _aim.onPanEnd();
                                        setState(() {});
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),

                // Damage flash vignette.
                AnimatedBuilder(
                  animation: _vignetteController,
                  builder: (context, _) {
                    if (_vignetteController.isDismissed) {
                      return const SizedBox.shrink();
                    }
                    return IgnorePointer(
                      child: Opacity(
                        opacity: _vignetteOpacity.value,
                        child: const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.95,
                              colors: [
                                Colors.transparent,
                                Color(0x88C41E1E),
                                Color(0xEEC41E1E),
                              ],
                              stops: [0.25, 0.65, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                // Level-up overlay.
                if (_showLevelUp)
                  AnimatedBuilder(
                    animation: _levelUpController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _levelUpOpacity.value,
                        child: Transform.scale(
                          scale: _levelUpScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: _LevelUpOverlay(
                      onSelect: _chooseUpgrade,
                      onDismiss: _skipLevelUp,
                    ),
                  ),

                // Pause overlay (sits above HUD; fades via own controller).
                PauseOverlay(
                  visible: _gameState.isPaused &&
                      !_gameState.awaitingLevelUp &&
                      !_showTutorial,
                  onResume: () => _setPaused(false),
                  onRestart: _restartRun,
                  onQuitToMenu: _quitToMenu,
                ),

                // First-match tutorial (or can be opened from Main Menu).
                HowToPlayOverlay(
                  visible: _showTutorial,
                  persistTutorialFlag: _persistTutorialFlag,
                  onDismiss: () {
                    setState(() {
                      _showTutorial = false;
                      _persistTutorialFlag = false;
                    });
                    _gameState.setPaused(false);
                    AudioManager.instance.resumeMusic();
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

Future<ui.Image> _loadUiImage(String asset) async {
  final data = await rootBundle.load(asset);
  final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
  final frame = await codec.getNextFrame();
  return frame.image;
}

/// Idle/walk sprite sheets for one equipped character id.
class _PlayerSpriteSet {
  _PlayerSpriteSet({
    required this.characterId,
    required this.idleDown,
    required this.idleSide,
    required this.idleUp,
    required this.walkDown,
    required this.walkSide,
    required this.walkUp,
  });

  final String characterId;
  final ui.Image idleDown;
  final ui.Image idleSide;
  final ui.Image idleUp;
  final ui.Image walkDown;
  final ui.Image walkSide;
  final ui.Image walkUp;

  static Future<_PlayerSpriteSet> load(String characterId) async {
    final id = AppAssets.gamePlayerIds.contains(characterId)
        ? characterId
        : 'wanderer';

    return _PlayerSpriteSet(
      characterId: id,
      idleDown: await _loadUiImage(AppAssets.gamePlayerIdle(id)),
      idleSide: await _loadUiImage(AppAssets.gamePlayerIdle(id, facing: 'side')),
      idleUp: await _loadUiImage(AppAssets.gamePlayerIdle(id, facing: 'up')),
      walkDown: await _loadUiImage(AppAssets.gamePlayerWalk(id)),
      walkSide: await _loadUiImage(AppAssets.gamePlayerWalk(id, facing: 'side')),
      walkUp: await _loadUiImage(AppAssets.gamePlayerWalk(id, facing: 'up')),
    );
  }

  void dispose() {
    idleDown.dispose();
    idleSide.dispose();
    idleUp.dispose();
    walkDown.dispose();
    walkSide.dispose();
    walkUp.dispose();
  }
}

class _EnemyKindSprites {
  _EnemyKindSprites({required this.idle, required this.walk});

  final ui.Image idle;
  final ui.Image walk;

  void dispose() {
    idle.dispose();
    walk.dispose();
  }
}

/// Idle/walk sheets keyed by [EnemyKind].
class _EnemySpriteAtlas {
  _EnemySpriteAtlas(this.byKind);

  final Map<EnemyKind, _EnemyKindSprites> byKind;

  static Future<_EnemySpriteAtlas> load() async {
    Future<_EnemyKindSprites> loadKind(String kind) async {
      return _EnemyKindSprites(
        idle: await _loadUiImage(AppAssets.gameEnemyIdle(kind)),
        walk: await _loadUiImage(AppAssets.gameEnemyWalk(kind)),
      );
    }

    return _EnemySpriteAtlas({
      EnemyKind.fast: await loadKind('fast'),
      EnemyKind.tank: await loadKind('tank'),
      EnemyKind.ranged: await loadKind('ranged'),
    });
  }

  _EnemyKindSprites? forKind(EnemyKind kind) => byKind[kind];

  void dispose() {
    for (final s in byKind.values) {
      s.dispose();
    }
  }
}

class _ArenaPainter extends CustomPainter {
  _ArenaPainter({
    required this.state,
    required this.playerSprites,
    required this.enemySprites,
    required this.envSprites,
    required this.xpOrbSprite,
    required this.magnetSprite,
    required this.aimRangeAlpha,
    required this.aimRangeRadius,
  });

  final GameState state;
  final _PlayerSpriteSet? playerSprites;
  final _EnemySpriteAtlas? enemySprites;
  final Map<String, ui.Image>? envSprites;
  final ui.Image? xpOrbSprite;
  final ui.Image? magnetSprite;
  final double aimRangeAlpha;
  final double aimRangeRadius;

  static const double _playerDrawSize = 36;
  static const Color _maroonGlow = Color(0xFFC41E1E);

  /// Pull saturated greens toward muted grey-fog (env props).
  static const ColorFilter _envMuteFilter = ColorFilter.matrix(<double>[
    0.28, 0.42, 0.18, 0, -12,
    0.26, 0.40, 0.18, 0, -10,
    0.24, 0.34, 0.26, 0, -6,
    0, 0, 0, 1, 0,
  ]);

  /// Soften enemy pack saturation toward pastel fog tone.
  static const ColorFilter _enemyMuteFilter = ColorFilter.matrix(<double>[
    0.55, 0.30, 0.15, 0, -6,
    0.25, 0.50, 0.15, 0, -4,
    0.20, 0.25, 0.45, 0, 2,
    0, 0, 0, 1, 0,
  ]);

  @override
  void paint(Canvas canvas, Size size) {
    _paintAimRange(canvas);
    _paintObstacles(canvas);

    // XP orbs
    final xpFallback = Paint()..color = const Color(0xFFE8C547);
    final spritePaint = Paint()..filterQuality = FilterQuality.none;
    for (final orb in state.xpOrbs) {
      final img = xpOrbSprite;
      if (img == null) {
        canvas.drawCircle(orb.position, orb.radius, xpFallback);
        continue;
      }
      final dst = Rect.fromCenter(
        center: orb.position,
        width: orb.radius * 2.4,
        height: orb.radius * 2.4,
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        spritePaint,
      );
    }

    // Magnet pickups
    for (final m in state.magnetPickups) {
      final img = magnetSprite;
      if (img == null) {
        canvas.drawCircle(
          m.position,
          m.radius,
          Paint()..color = const Color(0xFFB0B8C8),
        );
        continue;
      }
      final dst = Rect.fromCenter(
        center: m.position,
        width: 28,
        height: 28,
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        spritePaint,
      );
    }

    // Ground markers first, then sprites (enemies + player).
    for (final e in state.enemies) {
      _paintGroundMarker(canvas, e.position, e.radius * 1.7);
    }
    _paintGroundMarker(canvas, state.playerPosition, 16);

    // Enemies — sprite sheets (fallback to colored circles).
    for (final e in state.enemies) {
      _paintEnemy(canvas, e);
      // HP ring
      final hpRatio = (e.hp / e.maxHp).clamp(0.0, 1.0);
      final ring = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawArc(
        Rect.fromCircle(center: e.position, radius: e.radius + 3),
        -math.pi / 2,
        2 * math.pi * hpRatio,
        false,
        ring,
      );
    }

    // Projectiles
    final shotPaint = Paint()..color = const Color(0xFFFFE08A);
    for (final p in state.projectiles) {
      canvas.drawCircle(p.position, p.radius, shotPaint);
    }

    _paintPlayer(canvas);
  }

  /// Soft oval shadow under feet — cosmetic only (no hitbox change).
  void _paintGroundMarker(Canvas canvas, Offset position, double width) {
    final oval = Rect.fromCenter(
      center: Offset(position.dx, position.dy + 6),
      width: width,
      height: width * 0.38,
    );
    canvas.drawOval(
      oval,
      Paint()..color = Colors.black.withValues(alpha: 0.38),
    );
    canvas.drawOval(
      oval.inflate(1.2),
      Paint()
        ..color = const Color(0xFF2A1818).withValues(alpha: 0.22)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );
  }

  void _paintAimRange(Canvas canvas) {
    if (aimRangeAlpha <= 0.01) return;
    final opacity = (0.18 * aimRangeAlpha).clamp(0.0, 0.2);
    final fill = Paint()
      ..color = _maroonGlow.withValues(alpha: opacity)
      ..style = PaintingStyle.fill;
    final edge = Paint()
      ..color = _maroonGlow.withValues(alpha: opacity * 1.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(state.playerPosition, aimRangeRadius, fill);
    canvas.drawCircle(state.playerPosition, aimRangeRadius, edge);
  }

  void _paintObstacles(Canvas canvas) {
    // Grade trees/bushes/rocks into the arena's muted fog palette.
    canvas.saveLayer(null, Paint()..colorFilter = _envMuteFilter);
    final paint = Paint()..filterQuality = FilterQuality.none;
    for (final o in state.obstacles) {
      final img = envSprites?[o.assetPath];
      if (img == null) {
        canvas.drawCircle(
          o.position,
          o.radius,
          Paint()..color = const Color(0xFF3A2A22),
        );
        continue;
      }
      final dst = Rect.fromCenter(
        center: Offset(o.position.dx, o.position.dy - o.drawHeight * 0.18),
        width: o.drawWidth,
        height: o.drawHeight,
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        paint,
      );
    }
    canvas.restore();
  }

  void _paintEnemy(Canvas canvas, EnemyEntity e) {
    final sheets = enemySprites?.forKind(e.type);
    if (sheets == null) {
      final color = switch (e.type) {
        EnemyKind.fast => const Color(0xFF7EC8E3),
        EnemyKind.tank => const Color(0xFF6B3FA0),
        EnemyKind.ranged => const Color(0xFFC45C26),
      };
      canvas.drawCircle(e.position, e.radius, Paint()..color = color);
      return;
    }

    final sheet = e.moving ? sheets.walk : sheets.idle;
    final frameH = sheet.height;
    final frameW = frameH <= 0 ? sheet.width : frameH;
    final frameCount =
        frameW <= 0 ? 1 : math.max(1, sheet.width ~/ frameW);
    final frameIndex =
        e.moving ? (e.walkAnimTime * 8).floor() % frameCount : 0;

    final drawSize = e.radius * 2.35;
    final src = Rect.fromLTWH(
      (frameIndex * frameW).toDouble(),
      0,
      frameW.toDouble(),
      frameH.toDouble(),
    );
    // Anchor sprite slightly above the ground marker (feet at entity pos).
    final dst = Rect.fromCenter(
      center: const Offset(0, -2),
      width: drawSize,
      height: drawSize * (frameH / frameW),
    );

    canvas.saveLayer(null, Paint()..colorFilter = _enemyMuteFilter);
    canvas.translate(e.position.dx, e.position.dy);
    if (e.facingLeft) {
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      sheet,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.restore();
  }

  void _paintPlayer(Canvas canvas) {
    final sprites = playerSprites;
    if (sprites == null) {
      final playerPaint = Paint()..color = const Color(0xFFE8E8E8);
      canvas.drawCircle(state.playerPosition, 14, playerPaint);
      canvas.drawCircle(
        state.playerPosition,
        14,
        Paint()
          ..color = const Color(0xFFC41E1E)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.5,
      );
      return;
    }

    final angle = state.facingAngle;
    final ax = math.cos(angle);
    final ay = math.sin(angle);
    final vertical = ay.abs() >= ax.abs();
    final flipX = !vertical && ax < 0;

    final ui.Image sheet;
    if (vertical) {
      if (ay < 0) {
        sheet = state.playerMoving ? sprites.walkUp : sprites.idleUp;
      } else {
        sheet = state.playerMoving ? sprites.walkDown : sprites.idleDown;
      }
    } else {
      sheet = state.playerMoving ? sprites.walkSide : sprites.idleSide;
    }

    final frameH = sheet.height;
    final frameW = frameH <= 0 ? sheet.width : frameH;
    final frameCount =
        frameW <= 0 ? 1 : math.max(1, sheet.width ~/ frameW);
    // Idle = frame 0; walk cycle driven by displacement-scaled walkAnimTime.
    final frameIndex = state.playerMoving
        ? (state.walkAnimTime * 8).floor() % frameCount
        : 0;

    final src = Rect.fromLTWH(
      (frameIndex * frameW).toDouble(),
      0,
      frameW.toDouble(),
      frameH.toDouble(),
    );
    final dst = Rect.fromCenter(
      center: const Offset(0, -3),
      width: _playerDrawSize,
      height: _playerDrawSize * (frameH / frameW),
    );

    canvas.save();
    canvas.translate(state.playerPosition.dx, state.playerPosition.dy);
    if (flipX) {
      canvas.scale(-1, 1);
    }
    final paint = Paint()..filterQuality = FilterQuality.none;
    canvas.drawImageRect(sheet, src, dst, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) => true;
}

class _HpBar extends StatelessWidget {
  const _HpBar({
    required this.segments,
    required this.damagedIndex,
    required this.flash,
    required this.controller,
  });

  final int segments;
  final int damagedIndex;
  final Animation<double> flash;
  final AnimationController controller;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AppAssets.iconHp, width: 12, height: 12),
            const SizedBox(width: 6),
            Text(
              'VITALITY',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 9,
                letterSpacing: 2,
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        AnimatedBuilder(
          animation: controller,
          builder: (context, _) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(segments, (i) {
                final isEmpty = damagedIndex < 0 || i > damagedIndex;
                final isDamaged = i == damagedIndex && damagedIndex >= 0;
                final fill = isEmpty
                    ? 0.0
                    : isDamaged
                        ? flash.value
                        : 1.0;

                return Container(
                  width: 22,
                  height: 12,
                  margin: EdgeInsets.only(right: i == segments - 1 ? 0 : 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(2),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                      width: 0.8,
                    ),
                    boxShadow: isDamaged
                        ? [
                            BoxShadow(
                              color: _maroonGlow.withValues(
                                alpha: 0.55 * flash.value,
                              ),
                              blurRadius: 6 * flash.value,
                            ),
                          ]
                        : null,
                  ),
                  child: FractionallySizedBox(
                    widthFactor: 1,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1.5),
                        color: Color.lerp(
                          Colors.transparent,
                          isDamaged ? _maroonGlow : _maroon,
                          fill,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            );
          },
        ),
      ],
    );
  }
}

class _PickupToast extends StatelessWidget {
  const _PickupToast({required this.text, this.leading});

  final String text;
  final Widget? leading;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _maroonGlow.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: _maroonGlow.withValues(alpha: 0.3),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          leading ??
              Image.asset(AppAssets.iconEmbers, width: 16, height: 16),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 14,
              letterSpacing: 1.2,
              color: Colors.white.withValues(alpha: 0.92),
              shadows: [
                Shadow(
                  color: _maroonGlow.withValues(alpha: 0.6),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleControl extends StatelessWidget {
  const _CircleControl({
    required this.outerSize,
    required this.innerSize,
    this.label,
    this.knuckle = Offset.zero,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  final double outerSize;
  final double innerSize;
  final String? label;
  final Offset knuckle;
  final void Function(Offset localDeltaFromCenter)? onPanStart;
  final void Function(Offset localDeltaFromCenter)? onPanUpdate;
  final VoidCallback? onPanEnd;

  Offset _delta(Offset local) =>
      local - Offset(outerSize / 2, outerSize / 2);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: onPanStart == null
            ? null
            : (details) => onPanStart!(_delta(details.localPosition)),
        onPanUpdate: onPanUpdate == null
            ? null
            : (details) => onPanUpdate!(_delta(details.localPosition)),
        onPanEnd: onPanEnd == null ? null : (_) => onPanEnd!(),
        onPanCancel: onPanEnd,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: outerSize,
              height: outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.5,
                ),
              ),
            ),
            Transform.translate(
              offset: knuckle,
              child: Container(
                width: innerSize,
                height: innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: label == null
                    ? null
                    : Text(
                        label!,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 11,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.55),
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelUpOverlay extends StatelessWidget {
  const _LevelUpOverlay({
    required this.onSelect,
    required this.onDismiss,
  });

  final void Function(LevelUpUpgrade upgrade) onSelect;
  final VoidCallback onDismiss;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  static const List<_UpgradeOption> _upgrades = [
    _UpgradeOption(
      icon: Icons.favorite_border,
      imageAsset: AppAssets.iconHp,
      name: 'Bloodbound',
      description: 'Restore vitality and harden your flesh.',
      upgrade: LevelUpUpgrade.bloodbound,
    ),
    _UpgradeOption(
      icon: Icons.speed,
      name: 'Shadow Step',
      description: 'Move faster through the fog for a burst.',
      upgrade: LevelUpUpgrade.shadowStep,
    ),
    _UpgradeOption(
      icon: Icons.local_fire_department_outlined,
      imageAsset: AppAssets.iconEmbers,
      name: 'Ember Edge',
      description: 'Attacks leave lingering cinder damage.',
      upgrade: LevelUpUpgrade.emberEdge,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.72),
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 28),
            Text(
              'THE HOUR DEEPENS',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 16,
                letterSpacing: 3,
                color: _maroonGlow.withValues(alpha: 0.95),
                shadows: [
                  Shadow(
                    color: _maroonGlow.withValues(alpha: 0.5),
                    blurRadius: 12,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Choose an upgrade',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 12,
                letterSpacing: 1.5,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                itemCount: _upgrades.length,
                separatorBuilder: (_, _) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final option = _upgrades[index];
                  return _UpgradeCard(
                    upgrade: option,
                    onTap: () => onSelect(option.upgrade),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: onDismiss,
              child: Text(
                'Dismiss',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 12,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _UpgradeOption {
  const _UpgradeOption({
    required this.icon,
    required this.name,
    required this.description,
    required this.upgrade,
    this.imageAsset,
  });

  final IconData icon;
  final String? imageAsset;
  final String name;
  final String description;
  final LevelUpUpgrade upgrade;
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.upgrade,
    required this.onTap,
  });

  final _UpgradeOption upgrade;
  final VoidCallback onTap;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF121010),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _maroonGlow, width: 1.6),
            boxShadow: [
              BoxShadow(
                color: _maroonGlow.withValues(alpha: 0.4),
                blurRadius: 18,
                spreadRadius: 0.5,
              ),
              BoxShadow(
                color: _maroon.withValues(alpha: 0.2),
                blurRadius: 30,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: _maroon.withValues(alpha: 0.6),
                  ),
                ),
                child: upgrade.imageAsset != null
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Image.asset(
                          upgrade.imageAsset!,
                          fit: BoxFit.contain,
                        ),
                      )
                    : Icon(upgrade.icon, color: _maroonGlow, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      upgrade.name,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 16,
                        letterSpacing: 1.5,
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      upgrade.description,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 12,
                        height: 1.35,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
