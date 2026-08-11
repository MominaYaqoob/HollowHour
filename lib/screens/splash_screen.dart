import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import 'main_menu_screen.dart';

/// Splash — app-icon entrance, hourglass accent, tap to enter main menu.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);

  late final AnimationController _fogController;
  late final AnimationController _iconController;
  late final AnimationController _glowController;
  late final AnimationController _sandController;
  late final AnimationController _tapPulseController;

  late final Animation<double> _fogDrift;
  late final Animation<double> _fogOpacity;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;
  late final Animation<double> _glowPulse;
  late final Animation<double> _sandFall;
  late final Animation<double> _tapOpacity;

  bool _showSecondary = false;

  @override
  void initState() {
    super.initState();
    AudioManager.instance.playMusic();

    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    _fogDrift = Tween<double>(begin: -0.15, end: 0.15).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.25, end: 0.45), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.45, end: 0.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 0.35), weight: 1),
    ]).animate(_fogController);

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOutCubic),
    );
    _iconOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _iconController, curve: Curves.easeOut),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _glowPulse = Tween<double>(begin: 0.25, end: 0.65).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _sandController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _sandFall = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _sandController, curve: Curves.linear),
    );

    _tapPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _tapOpacity = Tween<double>(begin: 0.25, end: 0.9).animate(
      CurvedAnimation(parent: _tapPulseController, curve: Curves.easeInOut),
    );

    _iconController.forward();
    Future<void>.delayed(const Duration(milliseconds: 700), () {
      if (!mounted) return;
      setState(() => _showSecondary = true);
      _glowController.repeat(reverse: true);
      _sandController.repeat();
      _tapPulseController.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _fogController.dispose();
    _iconController.dispose();
    _glowController.dispose();
    _sandController.dispose();
    _tapPulseController.dispose();
    super.dispose();
  }

  void _onTap() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final h = size.height;
    final w = size.width;

    // Proportional scale — logo dominant, hourglass accent, tap grounded.
    final logoSize = (h * 0.18).clamp(120.0, 168.0);
    final gapLogoToHourglass = h * 0.042;
    final gapAboveTap = h * 0.06;
    final bottomInset = h * 0.10;
    final hourglassW = (w * 0.085).clamp(30.0, 40.0);
    final hourglassH = hourglassW * 1.45;
    final tapFontSize = (h * 0.0195).clamp(14.0, 17.0);

    return Scaffold(
      backgroundColor: _charcoal,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const FieldBackdrop(showField: false, fogOpacity: 0.18),
            AnimatedBuilder(
              animation: _fogController,
              builder: (context, _) {
                final driftX = _fogDrift.value * size.width;
                return Opacity(
                  opacity: _fogOpacity.value,
                  child: Stack(
                    children: [
                      Positioned(
                        left: driftX - size.width * 0.2,
                        top: size.height * 0.15,
                        child: _FogBlob(
                          width: size.width * 0.9,
                          height: size.height * 0.35,
                          color: const Color(0xFF2A2A2A),
                        ),
                      ),
                      Positioned(
                        left: -driftX - size.width * 0.1,
                        top: size.height * 0.45,
                        child: _FogBlob(
                          width: size.width * 1.1,
                          height: size.height * 0.4,
                          color: const Color(0xFF1C1C1C),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.15,
                  colors: [
                    Colors.transparent,
                    Color(0x88000000),
                    Color(0xEE000000),
                  ],
                  stops: [0.35, 0.75, 1.0],
                ),
              ),
            ),
            // Hierarchy: centered logo+hourglass cluster, tap near bottom.
            SafeArea(
              child: Column(
                children: [
                  Expanded(
                    child: Align(
                      alignment: const Alignment(0, -0.12),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: Listenable.merge([
                              _iconController,
                              _glowController,
                            ]),
                            builder: (context, _) {
                              return Opacity(
                                opacity: _iconOpacity.value,
                                child: Transform.scale(
                                  scale: _iconScale.value,
                                  child: Container(
                                    width: logoSize,
                                    height: logoSize,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        logoSize * 0.185,
                                      ),
                                      border: Border.all(
                                        color: const Color(0xFF8B1A1A)
                                            .withValues(alpha: 0.45),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              const Color(0xFFC41E1E).withValues(
                                            alpha: _showSecondary
                                                ? _glowPulse.value
                                                : 0.2,
                                          ),
                                          blurRadius:
                                              _showSecondary ? 28 : 10,
                                          spreadRadius:
                                              _showSecondary ? 2 : 0,
                                        ),
                                      ],
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Image.asset(
                                      AppAssets.brandingIcon,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                          SizedBox(height: gapLogoToHourglass),
                          SizedBox(
                            width: hourglassW,
                            height: hourglassH,
                            child: _showSecondary
                                ? AnimatedBuilder(
                                    animation: _sandController,
                                    builder: (context, _) {
                                      return CustomPaint(
                                        size: Size(hourglassW, hourglassH),
                                        painter: _HourglassPainter(
                                          progress: _sandFall.value,
                                        ),
                                      );
                                    },
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: gapAboveTap),
                  _showSecondary
                      ? AnimatedBuilder(
                          animation: _tapPulseController,
                          builder: (context, _) {
                            return Opacity(
                              opacity: _tapOpacity.value,
                              child: Text(
                                'Tap to Begin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'serif',
                                  fontSize: tapFontSize,
                                  letterSpacing: 3.5,
                                  color:
                                      Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            );
                          },
                        )
                      : SizedBox(height: tapFontSize * 1.35),
                  SizedBox(height: bottomInset),
                ],
              ),
            ),
          ],
        ),
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
            color: color.withValues(alpha: 0.6),
            blurRadius: 60,
            spreadRadius: 30,
          ),
        ],
      ),
    );
  }
}

class _HourglassPainter extends CustomPainter {
  _HourglassPainter({required this.progress});

  final double progress;

  static const Color _glass = Color(0xFF5A5A5A);
  static const Color _sand = Color(0xFF8B1A1A);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final midY = h / 2;

    final framePaint = Paint()
      ..color = _glass
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;

    final path = Path()
      ..moveTo(w * 0.15, 0)
      ..lineTo(w * 0.85, 0)
      ..lineTo(cx + 1.5, midY)
      ..lineTo(w * 0.85, h)
      ..lineTo(w * 0.15, h)
      ..lineTo(cx - 1.5, midY)
      ..close();

    canvas.drawPath(path, framePaint);

    final capPaint = Paint()
      ..color = _glass
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.1, 0), Offset(w * 0.9, 0), capPaint);
    canvas.drawLine(Offset(w * 0.1, h), Offset(w * 0.9, h), capPaint);

    final sandPaint = Paint()
      ..color = _sand
      ..style = PaintingStyle.fill;

    final topFill = (1.0 - progress).clamp(0.0, 1.0);
    if (topFill > 0.02) {
      final topDepth = midY * 0.55 * topFill;
      final topPath = Path()
        ..moveTo(cx - w * 0.22 * topFill, midY - topDepth - 2)
        ..lineTo(cx + w * 0.22 * topFill, midY - topDepth - 2)
        ..lineTo(cx + 1, midY - 2)
        ..lineTo(cx - 1, midY - 2)
        ..close();
      canvas.drawPath(topPath, sandPaint);
    }

    if (progress > 0.02 && progress < 0.98) {
      final streamPaint = Paint()
        ..color = _sand.withValues(alpha: 0.85)
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;
      final streamEnd = midY + (h - midY) * 0.55 * progress.clamp(0.15, 1.0);
      canvas.drawLine(Offset(cx, midY), Offset(cx, streamEnd), streamPaint);
    }

    final bottomFill = progress.clamp(0.0, 1.0);
    if (bottomFill > 0.02) {
      final pileH = (h - midY) * 0.5 * bottomFill;
      final pilePath = Path()
        ..moveTo(cx - w * 0.28 * bottomFill, h - 2)
        ..lineTo(cx + w * 0.28 * bottomFill, h - 2)
        ..lineTo(cx + w * 0.18 * bottomFill, h - 2 - pileH)
        ..lineTo(cx - w * 0.18 * bottomFill, h - 2 - pileH)
        ..close();
      canvas.drawPath(pilePath, sandPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _HourglassPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
