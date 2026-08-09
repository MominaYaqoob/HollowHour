import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../prefs/app_flags.dart';
import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import 'game_over_screen.dart';
import 'how_to_play_overlay.dart';
import 'pause_overlay.dart';
import 'win_screen.dart';

/// Static gameplay HUD mockup — visual layer only, no real gameplay logic.
class GameplayHudScreen extends StatefulWidget {
  const GameplayHudScreen({super.key});

  @override
  State<GameplayHudScreen> createState() => _GameplayHudScreenState();
}

class _GameplayHudScreenState extends State<GameplayHudScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  static const int _hpSegments = 6;
  static const int _damagedSegmentIndex = 4; // 0-based; segment 5 flashes

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

  bool _showPickup = false;
  bool _showLevelUp = false;
  bool _paused = false;
  bool _showTutorial = false;
  bool _persistTutorialFlag = false;
  Timer? _pickupAutoTimer;

  // Static countdown display for the mockup.
  static const String _timerText = '19:42';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _maybeShowFirstMatchTutorial();

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

    // Auto-demo pickup shortly after open.
    _pickupAutoTimer = Timer(const Duration(milliseconds: 900), _triggerPickup);
  }

  @override
  void dispose() {
    _pickupAutoTimer?.cancel();
    _damagedFlashController.dispose();
    _pickupController.dispose();
    _vignetteController.dispose();
    _levelUpController.dispose();
    super.dispose();
  }

  Future<void> _maybeShowFirstMatchTutorial() async {
    final seen = await AppFlags.hasSeenTutorial();
    if (!mounted || seen) return;
    setState(() {
      _showTutorial = true;
      _persistTutorialFlag = true;
    });
  }

  void _triggerPickup() {
    if (!mounted) return;
    setState(() => _showPickup = true);
    _pickupController.forward(from: 0);
  }

  void _triggerDamage() {
    _vignetteController.forward(from: 0);
  }

  Future<void> _openLevelUp() async {
    setState(() => _showLevelUp = true);
    await _levelUpController.forward(from: 0);
  }

  Future<void> _closeLevelUp() async {
    await _levelUpController.reverse();
    if (mounted) setState(() => _showLevelUp = false);
  }

  void _setPaused(bool value) {
    if (_paused == value) return;
    setState(() => _paused = value);
  }

  void _restartRun() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameplayHudScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _quitToMenu() {
    // Root is MainMenu after splash pushReplacement.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showGameOver() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameOverScreen(
          enemiesDefeated: 23,
          timeSurvived: '04:12',
          embersEarned: 185,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  void _showWin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const WinScreen(
          enemiesDefeated: 47,
          timeSurvived: '20:00',
          embersEarned: 320,
        ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
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

          // HUD chrome.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Stack(
                children: [
                  // Top-left HP.
                  Align(
                    alignment: Alignment.topLeft,
                    child: _HpBar(
                      segments: _hpSegments,
                      damagedIndex: _damagedSegmentIndex,
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
                          _timerText,
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
                        child: const _PickupToast(text: '+15 Embers'),
                      ),
                    ),

                  // Bottom-left joystick.
                  const Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: EdgeInsets.only(left: 8, bottom: 8),
                      child: _CircleControl(
                        outerSize: 118,
                        innerSize: 48,
                      ),
                    ),
                  ),

                  // Bottom-right shoot/aim.
                  const Align(
                    alignment: Alignment.bottomRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 8, bottom: 8),
                      child: _CircleControl(
                        outerSize: 96,
                        innerSize: 52,
                        label: 'AIM',
                      ),
                    ),
                  ),

                  // Demo controls (testing only).
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 4),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _DemoButton(
                            label: 'Pickup',
                            onTap: _triggerPickup,
                          ),
                          const SizedBox(height: 8),
                          _DemoButton(
                            label: 'Take Damage',
                            onTap: _triggerDamage,
                          ),
                          const SizedBox(height: 8),
                          _DemoButton(
                            label: 'Level Up',
                            onTap: _openLevelUp,
                          ),
                          const SizedBox(height: 8),
                          _DemoButton(
                            label: 'Game Over',
                            onTap: _showGameOver,
                          ),
                          const SizedBox(height: 8),
                          _DemoButton(
                            label: 'Win',
                            onTap: _showWin,
                          ),
                        ],
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
              child: _LevelUpOverlay(onDismiss: _closeLevelUp),
            ),

          // Pause overlay (sits above HUD; fades via own controller).
          PauseOverlay(
            visible: _paused,
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
            },
          ),
        ],
      ),
    );
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
                final isEmpty = i > damagedIndex;
                final isDamaged = i == damagedIndex;
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
  const _PickupToast({required this.text});

  final String text;

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
  });

  final double outerSize;
  final double innerSize;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: outerSize,
      height: outerSize,
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
          Container(
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
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  const _DemoButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 10,
              letterSpacing: 0.8,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelUpOverlay extends StatelessWidget {
  const _LevelUpOverlay({required this.onDismiss});

  final VoidCallback onDismiss;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  static const List<_UpgradeOption> _upgrades = [
    _UpgradeOption(
      icon: Icons.favorite_border,
      imageAsset: AppAssets.iconHp,
      name: 'Bloodbound',
      description: 'Restore vitality and harden your flesh.',
    ),
    _UpgradeOption(
      icon: Icons.speed,
      name: 'Shadow Step',
      description: 'Move faster through the fog for a burst.',
    ),
    _UpgradeOption(
      icon: Icons.local_fire_department_outlined,
      imageAsset: AppAssets.iconEmbers,
      name: 'Ember Edge',
      description: 'Attacks leave lingering cinder damage.',
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
                  return _UpgradeCard(
                    upgrade: _upgrades[index],
                    onTap: onDismiss,
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
    this.imageAsset,
  });

  final IconData icon;
  final String? imageAsset;
  final String name;
  final String description;
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
