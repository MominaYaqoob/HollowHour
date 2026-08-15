import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../ads/ad_manager.dart';
import '../audio/audio_manager.dart';
import '../game/aim_fire_controller.dart';
import '../game/game_loop.dart';
import '../game/game_mode.dart';
import '../game/game_state.dart';
import '../game/leveling.dart';
import '../game/player_controller.dart';
import '../game/rune_catalog.dart';
import '../game/weapon_catalog.dart';
import '../prefs/app_flags.dart';
import '../state/economy_state.dart';
import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import '../theme/maroon_loader.dart';
import 'game_over_screen.dart';
import 'how_to_play_overlay.dart';
import 'pause_overlay.dart';
import 'win_screen.dart';

/// Gameplay HUD shell — visual presentation + wired match loop.
class GameplayHudScreen extends StatefulWidget {
  const GameplayHudScreen({
    super.key,
    this.stageLevel = 1,
  });

  /// Campaign stage 1–30 (duration + spawn depth derived from this).
  final int stageLevel;

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
  late final AnimationController _controlsHintController;

  late final Animation<double> _damagedFlash;
  late final Animation<double> _pickupScale;
  late final Animation<double> _pickupOpacity;
  late final Animation<double> _vignetteOpacity;
  late final Animation<double> _levelUpOpacity;
  late final Animation<double> _levelUpScale;
  late final Animation<double> _controlsHintOpacity;

  late final GameState _gameState;
  late final GameLoop _loop;

  bool _sessionReady = false;
  bool _showPickup = false;
  bool _showLevelUp = false;
  bool _showTutorial = false;
  bool _persistTutorialFlag = false;
  bool _showControlsHint = false;
  String? _lastPickupSeen;
  bool _ending = false;
  bool _enteringLevel = true;
  bool _waitingOnAd = false;
  bool _showEndBanner = false;
  bool _endBannerWon = false;

  /// Loaded top-down sheets for the equipped character (idle/walk × facing).
  _PlayerSpriteSet? _playerSprites;
  _EnemySpriteAtlas? _enemySprites;
  Map<String, ui.Image>? _envSprites;
  ui.Image? _xpOrbSprite;
  ui.Image? _magnetSprite;

  PlayerController get _player => _loop.player;
  AimFireController get _aim => _loop.aim;

  /// Stable arena painter — repaints via GameState, not widget rebuilds.
  _ArenaPainter? _arenaPainter;
  Object? _arenaPainterKey;

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

    // Level-1 control hints: fade in → hold ~4.5s → fade out.
    _controlsHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5500),
    );
    _controlsHintOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 12,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 75),
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 13,
      ),
    ]).animate(_controlsHintController);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_sessionReady) return;
    _sessionReady = true;

    final economy = context.read<EconomyState>();
    final characterId = economy.equippedCharacterId ?? 'wanderer';
    final stage = widget.stageLevel.clamp(1, 30);
    final weapon = WeaponCatalog.forId(economy.equippedWeaponId);
    final runes = RuneCatalog.combined(economy.equippedRuneIds);
    final talentDamage = 12 + economy.talentLevel('damage') * 2.0;
    _gameState = GameState(
      hollowDepth: stageDepthForLevel(stage),
      enemyStatScale: stageEnemyStatScale(stage),
      gameMode: GameMode.standard,
      matchDuration: stageDurationForLevel(stage),
      playerCharacterId: characterId,
      startingMaxHp:
          100 + economy.talentLevel('maxhp') * 8 + runes.maxHp,
      startingMoveSpeed:
          175 + economy.talentLevel('speed') * 10.0 + runes.moveSpeed,
      startingDamage: (talentDamage + runes.damage) * weapon.damageMul,
      startingFireCooldown: 0.38 * weapon.fireCooldownMul,
      startingProjectileSpeed: 420 * weapon.projectileSpeedMul,
      startingProjectileRadius: 5 * weapon.projectileRadiusMul,
      startingAimRangeRadius:
          AimFireController.rangeIndicatorRadius * weapon.aimRangeMul,
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

    unawaited(_gateLevelEnter());
  }

  /// Brief enter gate so the match clock does not start under the loader / ad.
  Future<void> _gateLevelEnter() async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;

    // Level-start interstitial (once per run) — safer than level-end close bugs.
    final needsWait = !AdManager.instance.isInterstitialReady;
    if (needsWait && mounted) {
      setState(() => _waitingOnAd = true);
    }
    try {
      await AdManager.instance.showInterstitial(
        onPresented: () {
          if (mounted && _waitingOnAd) {
            setState(() => _waitingOnAd = false);
          }
        },
      );
    } catch (_) {}
    if (!mounted) return;
    if (_waitingOnAd) setState(() => _waitingOnAd = false);

    setState(() => _enteringLevel = false);
    unawaited(AudioManager.instance.ensureMusicPlaying());
    await _maybeShowFirstMatchTutorial();
    if (!mounted) return;
    _loop.start();
    // If HowToPlay is up, hints wait for its dismiss; otherwise start now.
    unawaited(_tryStartControlsHint());
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
    _controlsHintController.dispose();
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
      setState(() {
        _showTutorial = true;
        _persistTutorialFlag = true;
      });
    }
  }

  /// Level-1-only fading stick hints. Skips while HowToPlay is visible so the
  /// two never stack; after "Got it", [onDismiss] calls this again.
  Future<void> _tryStartControlsHint() async {
    if (!mounted) return;
    if (widget.stageLevel != 1) return;
    if (_showTutorial || _showControlsHint) return;
    if (await AppFlags.hasSeenControlsHint()) return;
    if (!mounted) return;

    await AppFlags.setHasSeenControlsHint(true);
    if (!mounted) return;

    setState(() => _showControlsHint = true);
    await Future<void>.delayed(const Duration(milliseconds: 500));
    if (!mounted || !_showControlsHint) return;

    await _controlsHintController.forward(from: 0);
    if (mounted) {
      setState(() => _showControlsHint = false);
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
            GameplayHudScreen(stageLevel: widget.stageLevel),
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
    required int levelReached,
    required bool canRevive,
  }) {
    if (!mounted || _ending) return;

    final economy = context.read<EconomyState>();
    final stage = widget.stageLevel.clamp(1, 30);

    // First death: keep this HUD alive under GameOver so revive can resume.
    // (No end-of-level interstitial here — player may still revive.)
    if (!won && canRevive) {
      Navigator.of(context).push(
        PageRouteBuilder(
          opaque: true,
          pageBuilder: (context, animation, secondaryAnimation) =>
              GameOverScreen(
            enemiesDefeated: killCount,
            timeSurvived: timeLabel,
            embersEarned: embersEarned,
            levelReached: stage,
            stageLevel: stage,
            showReviveButton: true,
            onConfirmLeave: () => economy.addEmbers(embersEarned),
            onReviveSuccess: _handleReviveSuccess,
          ),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 600),
        ),
      );
      return;
    }

    _ending = true;
    unawaited(_finishRun(
      won: won,
      killCount: killCount,
      timeLabel: timeLabel,
      embersEarned: embersEarned,
      stage: stage,
    ));
  }

  Future<void> _finishRun({
    required bool won,
    required int killCount,
    required String timeLabel,
    required int embersEarned,
    required int stage,
  }) async {
    final economy = context.read<EconomyState>();
    economy.addEmbers(embersEarned);
    if (won) {
      economy.updateCharacterLevel(_gameState.playerCharacterId, stage);
    }

    // Result popup only — interstitial runs at level start, not here.
    if (mounted) {
      setState(() {
        _endBannerWon = won;
        _showEndBanner = true;
        _waitingOnAd = false;
      });
    }
    await Future<void>.delayed(const Duration(milliseconds: 1700));
    if (!mounted) return;
    setState(() => _showEndBanner = false);

    final screen = won
        ? WinScreen(
            enemiesDefeated: killCount,
            timeSurvived: timeLabel,
            embersEarned: embersEarned,
            levelReached: stage,
          )
        : GameOverScreen(
            enemiesDefeated: killCount,
            timeSurvived: timeLabel,
            embersEarned: embersEarned,
            levelReached: stage,
            stageLevel: stage,
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

  void _handleReviveSuccess() {
    if (!mounted) return;
    _gameState.reviveWithPartialHp();
    _loop.resumeAfterRevive();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  _ArenaPainter _obtainArenaPainter() {
    final key = (
      _playerSprites,
      _enemySprites,
      _envSprites,
      _xpOrbSprite,
      _magnetSprite,
    );
    if (_arenaPainter == null || _arenaPainterKey != key) {
      _arenaPainterKey = key;
      _arenaPainter = _ArenaPainter(
        state: _gameState,
        aim: _aim,
        playerSprites: _playerSprites,
        enemySprites: _enemySprites,
        envSprites: _envSprites,
        xpOrbSprite: _xpOrbSprite,
        magnetSprite: _magnetSprite,
      );
    }
    return _arenaPainter!;
  }

  @override
  Widget build(BuildContext context) {
    if (!_sessionReady) {
      return const MaroonLoaderScaffold();
    }

    return ChangeNotifierProvider<GameState>.value(
      value: _gameState,
      child: Scaffold(
        backgroundColor: _charcoal,
        // Stack is built once per State.setState — NOT on every GameState tick.
        // Arena paints via CustomPainter(repaint: _gameState); HUD uses _GameSlice.
        body: Stack(
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

            // Playfield only — repaints from GameState without rebuilding widgets.
            LayoutBuilder(
              builder: (context, constraints) {
                final size =
                    Size(constraints.maxWidth, constraints.maxHeight);
                if (size != _gameState.viewSize) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _gameState.setViewSize(size);
                  });
                }
                return CustomPaint(
                  painter: _obtainArenaPainter(),
                  size: size,
                );
              },
            ),

            // HUD chrome — sticks stay outside 60fps; live readouts use slices.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Stack(
                  children: [
                    // Top-left HP — rebuild only when segment index changes.
                    Align(
                      alignment: Alignment.topLeft,
                      child: _GameSlice<int>(
                        listenable: _gameState,
                        selector: (s) {
                          if (s.playerHp <= 0) return -1;
                          final hpRatio = s.maxHp <= 0
                              ? 0.0
                              : (s.playerHp / s.maxHp).clamp(0.0, 1.0);
                          return math.max(
                            0,
                            (hpRatio * _hpSegments).ceil() - 1,
                          );
                        },
                        builder: (context, damagedIndex) => _HpBar(
                          segments: _hpSegments,
                          damagedIndex: damagedIndex,
                          flash: _damagedFlash,
                          controller: _damagedFlashController,
                        ),
                      ),
                    ),

                    // Top-right timer + pause (pause control is stable).
                    Align(
                      alignment: Alignment.topRight,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _GameSlice<String>(
                            listenable: _gameState,
                            selector: (s) => s.timerLabel,
                            builder: (context, label) => Text(
                              label,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2,
                                color: Colors.white.withValues(alpha: 0.88),
                                shadows: [
                                  Shadow(
                                    color: _maroon.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
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

                    // Center-top pickup notification (driven by local setState).
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
                            text: _gameState.lastPickupLabel ?? '+XP',
                          ),
                        ),
                      ),

                    // Magnet active indicator — only when active / second ticks.
                    _GameSlice<(bool, int)>(
                      listenable: _gameState,
                      selector: (s) =>
                          (s.magnetActive, s.magnetTimeLeft.ceil()),
                      builder: (context, slice) {
                        if (!slice.$1) return const SizedBox.shrink();
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: _PickupToast(
                              text: 'MAGNET ${slice.$2}s',
                              leading: Image.asset(
                                AppAssets.gameMagnet,
                                width: 18,
                                height: 18,
                                filterQuality: FilterQuality.none,
                              ),
                            ),
                          ),
                        );
                      },
                    ),

                    // Bottom-left move joystick — not under GameState ticks.
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8, bottom: 8),
                        child: _MoveJoystickControl(
                          outerSize: 96,
                          innerSize: 42,
                          maxKnuckle: (96 - 42) / 2,
                          readKnuckle: () =>
                              _player.knuckleOffset((96 - 42) / 2),
                          onPanStart: (delta) {
                            _player.setStickFromLocalDelta(delta, 48);
                          },
                          onPanUpdate: (delta) {
                            _player.setStickFromLocalDelta(delta, 48);
                          },
                          onPanEnd: () {
                            _player.clearStick();
                          },
                        ),
                      ),
                    ),

                    // Level-1 move hint (IgnorePointer — never blocks the stick).
                    if (_showControlsHint)
                      Align(
                        alignment: Alignment.bottomLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 112),
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _controlsHintController,
                              builder: (context, child) => Opacity(
                                opacity: _controlsHintOpacity.value,
                                child: child,
                              ),
                              child: const _ControlsHintChip(
                                label: 'Drag to Move',
                                arrowDown: true,
                              ),
                            ),
                          ),
                        ),
                      ),

                    // Bottom-right ammo (sliced) + AIM pad (stable gestures).
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8, bottom: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _GameSlice<(int, int, bool)>(
                              listenable: _gameState,
                              selector: (s) => (
                                s.currentAmmo,
                                s.maxAmmo,
                                s.isReloading,
                              ),
                              builder: (context, ammo) {
                                final current = ammo.$1;
                                final max = ammo.$2;
                                final reloading = ammo.$3;
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '${current.toString().padLeft(3, '0')}/${max.toString().padLeft(3, '0')}',
                                      style: TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: 1,
                                        color: reloading
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
                                    if (reloading)
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
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 6),
                            _AimCrosshairControl(
                              size: 96,
                              maxKnuckle: 22,
                              readKnuckle: () => _aim.knuckleOffset(22),
                              onPanStart: (delta) {
                                _aim.onPanStart(delta, 48);
                              },
                              onPanUpdate: (delta) {
                                _aim.onPanUpdate(delta, 48);
                              },
                              onPanEnd: () {
                                _aim.onPanEnd();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Level-1 AIM hint (IgnorePointer — never blocks the pad).
                    if (_showControlsHint)
                      Align(
                        alignment: Alignment.bottomRight,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 4, bottom: 112),
                          child: IgnorePointer(
                            child: AnimatedBuilder(
                              animation: _controlsHintController,
                              builder: (context, child) => Opacity(
                                opacity: _controlsHintOpacity.value,
                                child: child,
                              ),
                              child: const _ControlsHintChip(
                                label: 'Drag to Aim & Fire',
                                arrowDown: true,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
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

            // Pause overlay — rebuild only when pause / level-up flags change.
            _GameSlice<(bool, bool)>(
              listenable: _gameState,
              selector: (s) => (s.isPaused, s.awaitingLevelUp),
              builder: (context, flags) => PauseOverlay(
                visible: flags.$1 && !flags.$2 && !_showTutorial,
                onResume: () => _setPaused(false),
                onRestart: _restartRun,
                onQuitToMenu: _quitToMenu,
              ),
            ),

            // First-match tutorial (local setState visibility).
            HowToPlayOverlay(
              visible: _showTutorial,
              persistTutorialFlag: _persistTutorialFlag,
              onDismiss: () {
                setState(() {
                  _showTutorial = false;
                  _persistTutorialFlag = false;
                });
                _gameState.setPaused(false);
                // After full tutorial, show light Level-1 stick hints if needed.
                unawaited(_tryStartControlsHint());
              },
            ),

            if (_enteringLevel)
              const MaroonLoaderOverlay(message: 'Entering the Hollow…'),
            if (_showEndBanner)
              _LevelEndBanner(won: _endBannerWon),
            if (_waitingOnAd)
              const MaroonLoaderOverlay(
                message: 'Loading…',
                opaque: false,
              ),
          ],
        ),
      ),
    );
  }
}

/// Brief Cleared / Fail popup before the end-of-level ad.
class _LevelEndBanner extends StatelessWidget {
  const _LevelEndBanner({required this.won});

  final bool won;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final title = won ? 'Level Cleared' : 'Failed';
    final subtitle = won
        ? 'You survived the Hollow.'
        : 'The Hollow claims you.';

    return AbsorbPointer(
      child: ColoredBox(
        color: const Color(0xFF0A0A0A).withValues(alpha: 0.78),
        child: Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 22),
            decoration: BoxDecoration(
              color: const Color(0xFF121010),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (won ? _maroonGlow : _maroon).withValues(alpha: 0.65),
              ),
              boxShadow: [
                BoxShadow(
                  color: (won ? _maroonGlow : _maroon).withValues(alpha: 0.28),
                  blurRadius: 22,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.4,
                    color: Colors.white.withValues(alpha: 0.94),
                    shadows: [
                      Shadow(
                        color: _maroonGlow.withValues(alpha: 0.5),
                        blurRadius: 16,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.58),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft Level-1 control callout — light backing, maroon glow text, chevron.
class _ControlsHintChip extends StatelessWidget {
  const _ControlsHintChip({
    required this.label,
    required this.arrowDown,
  });

  final String label;
  final bool arrowDown;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 12,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.88),
              shadows: [
                Shadow(
                  color: _maroonGlow.withValues(alpha: 0.55),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ),
        if (arrowDown) ...[
          const SizedBox(height: 2),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 22,
            color: Colors.white.withValues(alpha: 0.7),
            shadows: [
              Shadow(
                color: _maroonGlow.withValues(alpha: 0.45),
                blurRadius: 6,
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Listens to [GameState] but only [setState]s when [selector] output changes.
class _GameSlice<T> extends StatefulWidget {
  const _GameSlice({
    required this.listenable,
    required this.selector,
    required this.builder,
  });

  final GameState listenable;
  final T Function(GameState state) selector;
  final Widget Function(BuildContext context, T value) builder;

  @override
  State<_GameSlice<T>> createState() => _GameSliceState<T>();
}

class _GameSliceState<T> extends State<_GameSlice<T>> {
  late T _value;

  @override
  void initState() {
    super.initState();
    _value = widget.selector(widget.listenable);
    widget.listenable.addListener(_onNotify);
  }

  @override
  void didUpdateWidget(covariant _GameSlice<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listenable != widget.listenable) {
      oldWidget.listenable.removeListener(_onNotify);
      widget.listenable.addListener(_onNotify);
      _value = widget.selector(widget.listenable);
    }
  }

  @override
  void dispose() {
    widget.listenable.removeListener(_onNotify);
    super.dispose();
  }

  void _onNotify() {
    final next = widget.selector(widget.listenable);
    if (next != _value) {
      setState(() => _value = next);
    }
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _value);
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
    required this.aim,
    required this.playerSprites,
    required this.enemySprites,
    required this.envSprites,
    required this.xpOrbSprite,
    required this.magnetSprite,
  }) : super(repaint: state);

  final GameState state;
  final AimFireController aim;
  final _PlayerSpriteSet? playerSprites;
  final _EnemySpriteAtlas? enemySprites;
  final Map<String, ui.Image>? envSprites;
  final ui.Image? xpOrbSprite;
  final ui.Image? magnetSprite;

  /// On-screen size for a walk-sheet frame (64px source). Idle sheets are
  /// often 32px and must scale with source pixels so idle ≠ 2× walk.
  static const double _playerDrawSize = 42;
  static const double _playerRefFramePx = 64;
  static const Color _maroonGlow = Color(0xFFC41E1E);

  /// Light fog grade for env props — keep trees visible on dark ground.
  static const ColorFilter _envMuteFilter = ColorFilter.matrix(<double>[
    0.72, 0.18, 0.10, 0, 8,
    0.16, 0.70, 0.14, 0, 6,
    0.14, 0.18, 0.68, 0, 10,
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
    // World-space draw; camera follows the player across the expanded map.
    final cam = state.cameraTopLeft;
    canvas.save();
    canvas.translate(-cam.dx, -cam.dy);

    _paintAimRange(canvas);

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

    // Ground markers: obstacles + enemies + player (trees no longer float).
    for (final o in state.obstacles) {
      _paintGroundMarker(canvas, o.position, o.radius * 2.1);
    }
    for (final e in state.enemies) {
      _paintGroundMarker(canvas, e.position, e.radius * 1.7);
    }
    _paintGroundMarker(canvas, state.playerPosition, 16);

    // Y-sort obstacles around the player so trunks sit in the arena plane.
    final playerY = state.playerPosition.dy;
    _paintObstacles(canvas, onlyIf: (o) => o.position.dy < playerY);

    // Enemies — sprite sheets (fallback to colored circles).
    for (final e in state.enemies) {
      _paintEnemy(canvas, e);
    }

    _paintPlayer(canvas);
    // HP ring on the player character only (not enemies).
    final playerHpRatio =
        (state.maxHp <= 0 ? 0.0 : state.playerHp / state.maxHp).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: state.playerPosition, radius: 18),
      -math.pi / 2,
      2 * math.pi * playerHpRatio,
      false,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Obstacles in front of the player (occlusion).
    _paintObstacles(canvas, onlyIf: (o) => o.position.dy >= playerY);

    // Projectiles
    final shotPaint = Paint()..color = const Color(0xFFFFE08A);
    for (final p in state.projectiles) {
      canvas.drawCircle(p.position, p.radius, shotPaint);
    }

    canvas.restore();
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
    if (aim.rangeIndicatorAlpha <= 0.01) return;
    // Range fill/ring removed — only the dotted trajectory aids aim.
    _paintAimTrajectory(canvas);
  }

  /// Visual-only dotted aim line (hit detection unchanged).
  void _paintAimTrajectory(Canvas canvas) {
    final aimRangeAlpha = aim.rangeIndicatorAlpha;
    if (aimRangeAlpha <= 0.01) return;
    final origin = state.playerPosition;
    final dir = Offset(
      math.cos(state.facingAngle),
      math.sin(state.facingAngle),
    );
    final end = origin + dir * state.aimRangeRadius;
    final paint = Paint()
      ..color = _maroonGlow.withValues(alpha: (0.55 * aimRangeAlpha).clamp(0.0, 0.7))
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    const dash = 7.0;
    const gap = 5.0;
    final total = (end - origin).distance;
    if (total < 1) return;
    final unit = (end - origin) / total;
    var drawn = 0.0;
    while (drawn < total) {
      final a = origin + unit * drawn;
      final b = origin + unit * math.min(drawn + dash, total);
      canvas.drawLine(a, b, paint);
      drawn += dash + gap;
    }
  }

  void _paintObstacles(
    Canvas canvas, {
    required bool Function(ObstacleEntity o) onlyIf,
  }) {
    final batch = state.obstacles.where(onlyIf).toList();
    if (batch.isEmpty) return;

    // Per-sprite mute via Paint.colorFilter (avoid expensive saveLayer).
    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..colorFilter = _envMuteFilter;
    for (final o in batch) {
      final img = envSprites?[o.assetPath];
      if (img == null || img.width <= 0 || img.height <= 0) {
        canvas.drawCircle(
          o.position,
          o.radius,
          Paint()..color = const Color(0xFF3A2A22),
        );
        continue;
      }
      // Foot-anchor: sprite bottom sits on the collision/shadow point.
      final dst = Rect.fromLTWH(
        o.position.dx - o.drawWidth / 2,
        o.position.dy - o.drawHeight + 4,
        o.drawWidth,
        o.drawHeight,
      );
      canvas.drawImageRect(
        img,
        Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
        dst,
        paint,
      );
    }
  }

  /// Soft maroon halo so enemies read against dark ground (player stays white).
  void _paintEnemyGlow(Canvas canvas, EnemyEntity e) {
    final r = e.radius * 1.55;
    canvas.drawCircle(
      e.position,
      r,
      Paint()..color = _maroonGlow.withValues(alpha: 0.16),
    );
    canvas.drawCircle(
      e.position,
      r * 0.72,
      Paint()..color = _maroonGlow.withValues(alpha: 0.22),
    );
    canvas.drawCircle(
      e.position,
      r,
      Paint()
        ..color = _maroonGlow.withValues(alpha: 0.55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8,
    );
  }

  void _paintEnemy(Canvas canvas, EnemyEntity e) {
    _paintEnemyGlow(canvas, e);

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

    canvas.save();
    canvas.translate(e.position.dx, e.position.dy);
    if (e.facingLeft) {
      canvas.scale(-1, 1);
    }
    canvas.drawImageRect(
      sheet,
      src,
      dst,
      Paint()
        ..filterQuality = FilterQuality.none
        ..colorFilter = _enemyMuteFilter,
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
    // Same world px per source px for idle (32) and walk (64) sheets.
    final scale = _playerDrawSize / _playerRefFramePx;
    final dst = Rect.fromCenter(
      center: const Offset(0, -3),
      width: frameW * scale,
      height: frameH * scale,
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
  bool shouldRepaint(covariant _ArenaPainter oldDelegate) {
    // Frame motion is driven by super(repaint: state). Rebuild painter only when
    // sprite atlases change (async load) or aim controller identity changes.
    return oldDelegate.state != state ||
        oldDelegate.aim != aim ||
        oldDelegate.playerSprites != playerSprites ||
        oldDelegate.enemySprites != enemySprites ||
        oldDelegate.envSprites != envSprites ||
        oldDelegate.xpOrbSprite != xpOrbSprite ||
        oldDelegate.magnetSprite != magnetSprite;
  }
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

/// Left move stick — grey ring + maroon knuckle (How-to-Play diagram).
/// Local [setState] only — does not rebuild the whole gameplay HUD.
class _MoveJoystickControl extends StatefulWidget {
  const _MoveJoystickControl({
    required this.outerSize,
    required this.innerSize,
    required this.maxKnuckle,
    required this.readKnuckle,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  final double outerSize;
  final double innerSize;
  final double maxKnuckle;
  final Offset Function() readKnuckle;
  final void Function(Offset localDeltaFromCenter)? onPanStart;
  final void Function(Offset localDeltaFromCenter)? onPanUpdate;
  final VoidCallback? onPanEnd;

  @override
  State<_MoveJoystickControl> createState() => _MoveJoystickControlState();
}

class _MoveJoystickControlState extends State<_MoveJoystickControl> {
  Offset _knuckle = Offset.zero;

  Offset _delta(Offset local) =>
      local - Offset(widget.outerSize / 2, widget.outerSize / 2);

  void _syncKnuckle() {
    final next = widget.readKnuckle();
    if (next != _knuckle) setState(() => _knuckle = next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.outerSize,
      height: widget.outerSize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.onPanStart == null
            ? null
            : (details) {
                widget.onPanStart!(_delta(details.localPosition));
                _syncKnuckle();
              },
        onPanUpdate: widget.onPanUpdate == null
            ? null
            : (details) {
                widget.onPanUpdate!(_delta(details.localPosition));
                _syncKnuckle();
              },
        onPanEnd: widget.onPanEnd == null
            ? null
            : (_) {
                widget.onPanEnd!();
                _syncKnuckle();
              },
        onPanCancel: widget.onPanEnd == null
            ? null
            : () {
                widget.onPanEnd!();
                _syncKnuckle();
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.outerSize,
              height: widget.outerSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.22),
                  width: 1.5,
                ),
              ),
            ),
            Transform.translate(
              offset: _knuckle,
              child: Container(
                width: widget.innerSize,
                height: widget.innerSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B1A1A).withValues(alpha: 0.85),
                  border: Border.all(
                    color: const Color(0xFFC41E1E),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC41E1E).withValues(alpha: 0.35),
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Red crosshair aim pad (matches How-to-Play diagram; no gray AIM disc).
/// Local [setState] only — does not rebuild the whole gameplay HUD.
class _AimCrosshairControl extends StatefulWidget {
  const _AimCrosshairControl({
    required this.size,
    required this.maxKnuckle,
    required this.readKnuckle,
    this.onPanStart,
    this.onPanUpdate,
    this.onPanEnd,
  });

  final double size;
  final double maxKnuckle;
  final Offset Function() readKnuckle;
  final void Function(Offset localDeltaFromCenter)? onPanStart;
  final void Function(Offset localDeltaFromCenter)? onPanUpdate;
  final VoidCallback? onPanEnd;

  @override
  State<_AimCrosshairControl> createState() => _AimCrosshairControlState();
}

class _AimCrosshairControlState extends State<_AimCrosshairControl> {
  Offset _knuckle = Offset.zero;

  Offset _delta(Offset local) =>
      local - Offset(widget.size / 2, widget.size / 2);

  void _syncKnuckle() {
    final next = widget.readKnuckle();
    if (next != _knuckle) setState(() => _knuckle = next);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: widget.onPanStart == null
            ? null
            : (details) {
                widget.onPanStart!(_delta(details.localPosition));
                _syncKnuckle();
              },
        onPanUpdate: widget.onPanUpdate == null
            ? null
            : (details) {
                widget.onPanUpdate!(_delta(details.localPosition));
                _syncKnuckle();
              },
        onPanEnd: widget.onPanEnd == null
            ? null
            : (_) {
                widget.onPanEnd!();
                _syncKnuckle();
              },
        onPanCancel: widget.onPanEnd == null
            ? null
            : () {
                widget.onPanEnd!();
                _syncKnuckle();
              },
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.18),
                border: Border.all(
                  color: const Color(0xFFC41E1E).withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
            ),
            Transform.translate(
              offset: _knuckle,
              child: SizedBox(
                width: widget.size * 0.72,
                height: widget.size * 0.72,
                child: const CustomPaint(painter: _AimCrosshairPainter()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AimCrosshairPainter extends CustomPainter {
  const _AimCrosshairPainter();

  static const Color _line = Color(0xFFC41E1E);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _line.withValues(alpha: 0.9)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final c = Offset(size.width / 2, size.height / 2);
    final r = size.shortestSide * 0.28;

    canvas.drawCircle(c, r, paint);
    canvas.drawCircle(
      c,
      3.5,
      Paint()..color = _line.withValues(alpha: 0.95),
    );

    final arm = size.shortestSide * 0.42;
    final gap = r + 4;
    canvas.drawLine(Offset(c.dx, c.dy - arm), Offset(c.dx, c.dy - gap), paint);
    canvas.drawLine(Offset(c.dx, c.dy + gap), Offset(c.dx, c.dy + arm), paint);
    canvas.drawLine(Offset(c.dx - arm, c.dy), Offset(c.dx - gap, c.dy), paint);
    canvas.drawLine(Offset(c.dx + gap, c.dy), Offset(c.dx + arm, c.dy), paint);

    // Soft drag hint (same spirit as help diagram).
    final hint = Paint()
      ..color = Colors.white.withValues(alpha: 0.28)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(size.width - 8, 12),
      Offset(size.width - 22, 26),
      hint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      name: 'More Health',
      description: 'Heal yourself and raise max HP.',
      upgrade: LevelUpUpgrade.bloodbound,
    ),
    _UpgradeOption(
      icon: Icons.speed,
      name: 'Move Faster',
      description: 'Run quicker around the map.',
      upgrade: LevelUpUpgrade.shadowStep,
    ),
    _UpgradeOption(
      icon: Icons.local_fire_department_outlined,
      imageAsset: AppAssets.iconEmbers,
      name: 'Stronger Shots',
      description: 'Your attacks deal more damage.',
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
              'LEVEL UP',
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
              'Pick one power-up',
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
