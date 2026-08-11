import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../prefs/app_flags.dart';
import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import 'splash_screen.dart';

/// First-launch welcome / disclaimer — then proceeds to [SplashScreen].
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  /// Coordinated staged entrance (0–1900ms).
  late final AnimationController _entryController;
  late final AnimationController _fogController;
  late final AnimationController _emberController;
  late final AnimationController _buttonIdleController;

  late final Animation<double> _atmosphereOpacity;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _logoScale;
  late final Animation<double> _headingOpacity;
  late final Animation<Offset> _headingSlide;
  late final Animation<double> _bodyOpacity;
  late final Animation<double> _buttonReveal;
  late final Animation<double> _buttonScale;
  late final Animation<double> _skipOpacity;

  late final Animation<double> _fogDrift;
  late final Animation<double> _fogOpacity;
  late final Animation<double> _buttonIdleGlow;

  late final List<_EmberSpec> _embers;

  @override
  void initState() {
    super.initState();
    // Keep ambient running from first screen if Background Sound is on.
    AudioManager.instance.playMusic();

    final rng = math.Random(7);
    _embers = List.generate(12, (i) {
      return _EmberSpec(
        x: rng.nextDouble(),
        startY: 0.55 + rng.nextDouble() * 0.45,
        size: 1.6 + rng.nextDouble() * 2.4,
        speed: 0.12 + rng.nextDouble() * 0.22,
        phase: rng.nextDouble(),
        warmth: rng.nextBool(),
      );
    });

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1900),
    );

    // 0–600ms atmosphere
    _atmosphereOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.32, curve: Curves.easeOut),
    );

    // 400–900ms logo
    _logoOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.21, 0.47, curve: Curves.easeOut),
    );
    _logoScale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.21, 0.47, curve: Curves.easeOutCubic),
      ),
    );

    // 800–1300ms heading
    _headingOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.42, 0.68, curve: Curves.easeOut),
    );
    _headingSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.42, 0.68, curve: Curves.easeOutCubic),
      ),
    );

    // 1100–1600ms body + fiction line
    _bodyOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.58, 0.84, curve: Curves.easeOut),
    );

    // 1400–1900ms CTA
    _buttonReveal = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.74, 1.0, curve: Curves.easeOut),
    );
    _buttonScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _entryController,
        curve: const Interval(0.74, 1.0, curve: Curves.easeOutBack),
      ),
    );

    // Skip fades in last, faintly
    _skipOpacity = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.86, 1.0, curve: Curves.easeOut),
    );

    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
    _fogDrift = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.16, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.14, end: 0.24), weight: 1),
    ]).animate(_fogController);

    _emberController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    _buttonIdleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _buttonIdleGlow = CurvedAnimation(
      parent: _buttonIdleController,
      curve: Curves.easeInOut,
    );

    _entryController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        _buttonIdleController.repeat(reverse: true);
      }
    });

    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _fogController.dispose();
    _emberController.dispose();
    _buttonIdleController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    AudioManager.instance.playTap();
    await AppFlags.setHasSeenOnboarding(true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const SplashScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _charcoal,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Atmosphere fades in with entry (0–600ms).
          FadeTransition(
            opacity: _atmosphereOpacity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const FieldBackdrop(
                  showField: true,
                  fogOpacity: 0.22,
                  fieldOpacity: 0.78,
                ),
                AnimatedBuilder(
                  animation: _fogController,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _fogOpacity.value,
                      child: Stack(
                        children: [
                          Positioned(
                            left:
                                _fogDrift.value * size.width - size.width * 0.2,
                            top: size.height * 0.12,
                            child: _FogBlob(
                              width: size.width * 1.05,
                              height: size.height * 0.32,
                              color: const Color(0xFF242020),
                            ),
                          ),
                          Positioned(
                            left: -_fogDrift.value * size.width,
                            bottom: size.height * 0.1,
                            child: _FogBlob(
                              width: size.width * 1.15,
                              height: size.height * 0.36,
                              color: const Color(0xFF1A1515),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                AnimatedBuilder(
                  animation: _emberController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _EmberPainter(
                        progress: _emberController.value,
                        embers: _embers,
                        maroon: _maroonGlow,
                        amber: const Color(0xFFD4A24C),
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.55),
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                        stops: const [0.0, 0.32, 0.68, 1.0],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 22),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: FadeTransition(
                      opacity: _skipOpacity,
                      child: TextButton(
                        onPressed: _continue,
                        style: TextButton.styleFrom(
                          foregroundColor:
                              Colors.white.withValues(alpha: 0.4),
                          visualDensity: VisualDensity.compact,
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            letterSpacing: 1.6,
                            color: Colors.white.withValues(alpha: 0.38),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxHeight < 520;
                        final logoWidth =
                            size.width * (compact ? 0.78 : 0.86);

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: constraints.maxHeight,
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Hero wordmark only — no app-icon badge.
                                FadeTransition(
                                  opacity: _logoOpacity,
                                  child: ScaleTransition(
                                    scale: _logoScale,
                                    child: _GlowingLogo(width: logoWidth),
                                  ),
                                ),
                                SizedBox(height: compact ? 36 : 48),
                                SlideTransition(
                                  position: _headingSlide,
                                  child: FadeTransition(
                                    opacity: _headingOpacity,
                                    child: Text(
                                      'Welcome to the Hollow',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontFamily: 'serif',
                                        fontSize: compact ? 22 : 26,
                                        letterSpacing: 3.2,
                                        height: 1.2,
                                        color: Colors.white
                                            .withValues(alpha: 0.92),
                                        shadows: [
                                          Shadow(
                                            color: _maroonGlow.withValues(
                                              alpha: 0.4,
                                            ),
                                            blurRadius: 14,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: compact ? 14 : 18),
                                FadeTransition(
                                  opacity: _bodyOpacity,
                                  child: Column(
                                    children: [
                                      Text(
                                        'Pick a character, choose a level, and survive '
                                        'the timer. Clear stages to unlock the next — '
                                        'finish Level 30 to free the next soul.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontSize: compact ? 14 : 15,
                                          height: 1.5,
                                          letterSpacing: 0.4,
                                          color: Colors.white
                                              .withValues(alpha: 0.58),
                                        ),
                                      ),
                                      const SizedBox(height: 14),
                                      Text(
                                        'Left stick to move. Aim on the right. Embers buy power.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontFamily: 'serif',
                                          fontStyle: FontStyle.italic,
                                          fontSize: 12,
                                          letterSpacing: 0.7,
                                          color: Colors.white
                                              .withValues(alpha: 0.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 10),
                  FadeTransition(
                    opacity: _buttonReveal,
                    child: ScaleTransition(
                      scale: _buttonScale,
                      child: AnimatedBuilder(
                        animation: _buttonIdleController,
                        builder: (context, child) {
                          return _EnterButton(
                            onTap: _continue,
                            idleGlow: _buttonIdleGlow.value,
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontal logo with soft maroon radial glow — no hard box/border.
class _GlowingLogo extends StatelessWidget {
  const _GlowingLogo({required this.width});

  final double width;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final height = width * 0.38;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft radial glow blooming from darkness.
          IgnorePointer(
            child: Container(
              width: width * 0.85,
              height: height * 1.35,
              decoration: BoxDecoration(
                shape: BoxShape.rectangle,
                borderRadius: BorderRadius.circular(height),
                gradient: RadialGradient(
                  colors: [
                    _maroonGlow.withValues(alpha: 0.38),
                    _maroonGlow.withValues(alpha: 0.12),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.4, 1.0],
                ),
              ),
            ),
          ),
          // Dissolve logo edges into fog (masks flat PNG plate).
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              return RadialGradient(
                center: Alignment.center,
                radius: 0.82,
                colors: [
                  Colors.white,
                  Colors.white,
                  Colors.white.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.72, 1.0],
              ).createShader(bounds);
            },
            child: Image.asset(
              AppAssets.brandingLogo,
              width: width,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, _, _) => Text(
                'HOLLOW HOUR',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 28,
                  letterSpacing: 4,
                  color: Colors.white.withValues(alpha: 0.9),
                  shadows: [
                    Shadow(
                      color: _maroonGlow.withValues(alpha: 0.5),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterButton extends StatefulWidget {
  const _EnterButton({
    required this.onTap,
    required this.idleGlow,
  });

  final VoidCallback onTap;
  final double idleGlow;

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _press;
  late final Animation<double> _scale;
  late final Animation<double> _pressGlow;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1.2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.8,
      ),
    ]).animate(_press);
    _pressGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1.5),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _press.forward(from: 0);
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, _) {
          final glow = (0.38 +
                  widget.idleGlow * 0.4 +
                  _pressGlow.value * 0.45)
              .clamp(0.0, 1.0);
          return Transform.scale(
            scale: _scale.value,
            child: Center(
              child: Container(
                width: 280,
                height: 54,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.55),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: Color.lerp(_maroon, _maroonGlow, glow)!,
                    width: 1.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _maroonGlow.withValues(alpha: 0.38 * glow),
                      blurRadius: 20 * glow,
                      spreadRadius: 1 * glow,
                    ),
                  ],
                ),
                child: Text(
                  'Enter the Hollow',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 17,
                    letterSpacing: 2.5,
                    color: Colors.white.withValues(alpha: 0.92),
                    shadows: [
                      Shadow(
                        color: _maroonGlow.withValues(alpha: 0.5 * glow),
                        blurRadius: 8 * glow,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FogBlob extends StatelessWidget {
  const _FogBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 50,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

class _EmberSpec {
  const _EmberSpec({
    required this.x,
    required this.startY,
    required this.size,
    required this.speed,
    required this.phase,
    required this.warmth,
  });

  final double x;
  final double startY;
  final double size;
  final double speed;
  final double phase;
  final bool warmth;
}

class _EmberPainter extends CustomPainter {
  _EmberPainter({
    required this.progress,
    required this.embers,
    required this.maroon,
    required this.amber,
  });

  final double progress;
  final List<_EmberSpec> embers;
  final Color maroon;
  final Color amber;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;

    for (final ember in embers) {
      final t = (progress + ember.phase) % 1.0;
      final y = ember.startY - t * ember.speed * 1.35;
      final wrappedY = y < -0.05 ? y + 1.15 : y;
      final fade = (1.0 - (t * 1.15)).clamp(0.0, 1.0);
      final driftX =
          ember.x + math.sin((progress + ember.phase) * math.pi * 2) * 0.02;

      final paint = Paint()
        ..color = (ember.warmth ? amber : maroon).withValues(
          alpha: 0.18 + fade * 0.45,
        )
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawCircle(
        Offset(driftX * size.width, wrappedY * size.height),
        ember.size,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _EmberPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
