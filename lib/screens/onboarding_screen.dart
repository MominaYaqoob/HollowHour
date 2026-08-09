import 'package:flutter/material.dart';

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
    with SingleTickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _fogController;
  late final Animation<double> _fogDrift;
  late final Animation<double> _fogOpacity;

  @override
  void initState() {
    super.initState();
    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _fogDrift = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.34), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.34, end: 0.15), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.26), weight: 1),
    ]).animate(_fogController);
  }

  @override
  void dispose() {
    _fogController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
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
          const FieldBackdrop(showField: false, fogOpacity: 0.16),
          AnimatedBuilder(
            animation: _fogController,
            builder: (context, _) {
              return Opacity(
                opacity: _fogOpacity.value,
                child: Stack(
                  children: [
                    Positioned(
                      left: _fogDrift.value * size.width - size.width * 0.2,
                      top: size.height * 0.2,
                      child: _FogBlob(
                        width: size.width * 1.0,
                        height: size.height * 0.32,
                        color: const Color(0xFF242020),
                      ),
                    ),
                    Positioned(
                      left: -_fogDrift.value * size.width,
                      bottom: size.height * 0.18,
                      child: _FogBlob(
                        width: size.width * 1.1,
                        height: size.height * 0.34,
                        color: const Color(0xFF1A1515),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: TextButton(
                      onPressed: _continue,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 14,
                          letterSpacing: 1.5,
                          color: Colors.white.withValues(alpha: 0.45),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(flex: 2),
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _maroonGlow.withValues(alpha: 0.5),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _maroonGlow.withValues(alpha: 0.35),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      AppAssets.brandingIcon,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Welcome to the Hollow',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 28,
                      letterSpacing: 2,
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: [
                        Shadow(
                          color: _maroonGlow.withValues(alpha: 0.45),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'The hour is thin tonight. Fog claims the living, '
                    'and only embers keep the dark at bay.\n\n'
                    'This is a work of fiction. Survive what you can — '
                    'and remember: the Hollow always waits.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 14,
                      height: 1.55,
                      letterSpacing: 0.4,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const Spacer(flex: 3),
                  _EnterButton(onTap: _continue),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EnterButton extends StatefulWidget {
  const _EnterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_EnterButton> createState() => _EnterButtonState();
}

class _EnterButtonState extends State<_EnterButton>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
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
    ]).animate(_controller);
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 1.5),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _controller.forward(from: 0);
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final glow = _glow.value;
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: double.infinity,
              height: 54,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Color.lerp(_maroon, _maroonGlow, glow)!,
                  width: 1.7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _maroonGlow.withValues(alpha: 0.35 * glow),
                    blurRadius: 18 * glow,
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
