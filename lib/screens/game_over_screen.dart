import 'package:flutter/material.dart';

import '../theme/field_backdrop.dart';
import 'gameplay_hud_screen.dart';

/// Game-over / results screen — dramatic headline, counting stats, retry CTA.
class GameOverScreen extends StatefulWidget {
  const GameOverScreen({
    super.key,
    this.enemiesDefeated = 23,
    this.timeSurvived = '04:12',
    this.embersEarned = 185,
    this.headline = 'The Hollow Claims You',
  });

  final int enemiesDefeated;
  final String timeSurvived;
  final int embersEarned;
  final String headline;

  @override
  State<GameOverScreen> createState() => _GameOverScreenState();
}

class _GameOverScreenState extends State<GameOverScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _fogController;
  late final AnimationController _headlineController;
  late final AnimationController _statsController;

  late final Animation<double> _fogDrift;
  late final Animation<double> _fogOpacity;
  late final Animation<double> _headlineOpacity;
  late final Animation<double> _headlineScale;
  late final Animation<double> _statsProgress;

  @override
  void initState() {
    super.initState();

    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();

    _fogDrift = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.16, end: 0.32), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.32, end: 0.14), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.14, end: 0.24), weight: 1),
    ]).animate(_fogController);

    // Headline: delayed ~0.5s, then slow fade + slight scale-in.
    _headlineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _headlineOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headlineController,
        curve: const Interval(0.0, 0.85, curve: Curves.easeOut),
      ),
    );
    _headlineScale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _headlineController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // Stats count-up over ~1s, starts after headline begins.
    _statsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _statsProgress = CurvedAnimation(
      parent: _statsController,
      curve: Curves.easeOutCubic,
    );

    Future<void>.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _headlineController.forward();
    });
    Future<void>.delayed(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      _statsController.forward();
    });
  }

  @override
  void dispose() {
    _fogController.dispose();
    _headlineController.dispose();
    _statsController.dispose();
    super.dispose();
  }

  void _retry() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const GameplayHudScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _mainMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _charcoal,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FieldBackdrop(showField: true, fogOpacity: 0.16),
          AnimatedBuilder(
            animation: _fogController,
            builder: (context, _) {
              return Opacity(
                opacity: _fogOpacity.value,
                child: Stack(
                  children: [
                    Positioned(
                      left: _fogDrift.value * size.width - size.width * 0.2,
                      top: size.height * 0.18,
                      child: _FogBlob(
                        width: size.width * 1.05,
                        height: size.height * 0.3,
                        color: const Color(0xFF242020),
                      ),
                    ),
                    Positioned(
                      left: -_fogDrift.value * size.width,
                      bottom: size.height * 0.2,
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
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.35),
                  radius: 1.1,
                  colors: [
                    _maroon.withValues(alpha: 0.12),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  AnimatedBuilder(
                    animation: _headlineController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _headlineOpacity.value,
                        child: Transform.scale(
                          scale: _headlineScale.value,
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      widget.headline,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        height: 1.25,
                        color: Colors.white.withValues(alpha: 0.92),
                        shadows: [
                          Shadow(
                            color: _maroonGlow.withValues(alpha: 0.55),
                            blurRadius: 22,
                          ),
                          Shadow(
                            color: _maroon.withValues(alpha: 0.4),
                            blurRadius: 40,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 36),
                  AnimatedBuilder(
                    animation: _statsController,
                    builder: (context, _) {
                      final t = _statsProgress.value;
                      return _StatsPanel(
                        enemiesDefeated: (widget.enemiesDefeated * t).round(),
                        timeSurvived: widget.timeSurvived,
                        timeProgress: t,
                        embersEarned: (widget.embersEarned * t).round(),
                      );
                    },
                  ),
                  const Spacer(flex: 3),
                  _GlowButton(
                    label: 'Retry',
                    primary: true,
                    onTap: _retry,
                  ),
                  const SizedBox(height: 12),
                  _GlowButton(
                    label: 'Main Menu',
                    primary: false,
                    onTap: _mainMenu,
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

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.enemiesDefeated,
    required this.timeSurvived,
    required this.timeProgress,
    required this.embersEarned,
  });

  final int enemiesDefeated;
  final String timeSurvived;
  final double timeProgress;
  final int embersEarned;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          _StatRow(
            label: 'Enemies Defeated',
            value: '$enemiesDefeated',
          ),
          const _StatDivider(),
          _StatRow(
            label: 'Time Survived',
            value: _revealTime(timeSurvived, timeProgress),
          ),
          const _StatDivider(),
          _StatRow(
            label: 'Embers Earned',
            value: '$embersEarned',
            accent: true,
          ),
        ],
      ),
    );
  }

  /// Reveals the time string progressively so it still "counts" visually.
  static String _revealTime(String time, double progress) {
    if (progress <= 0) return '00:00';
    if (progress >= 1) return time;

    final parts = time.split(':');
    if (parts.length != 2) return time;
    final totalSeconds =
        (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    final current = (totalSeconds * progress).round();
    final m = (current ~/ 60).toString().padLeft(2, '0');
    final s = (current % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    required this.value,
    this.accent = false,
  });

  final String label;
  final String value;
  final bool accent;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 13,
                letterSpacing: 1,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: accent
                  ? _maroonGlow.withValues(alpha: 0.95)
                  : Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _GlowButton extends StatefulWidget {
  const _GlowButton({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_GlowButton> createState() => _GlowButtonState();
}

class _GlowButtonState extends State<_GlowButton>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glowPulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: widget.primary ? 1.06 : 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1.4,
      ),
      if (widget.primary)
        TweenSequenceItem(
          tween: Tween(begin: 1.06, end: 1.0)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 0.8,
        ),
    ]).animate(_controller);

    _glowPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.35), weight: 1.5),
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
          final glow = widget.primary ? _glowPulse.value : 0.2;
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: double.infinity,
              height: widget.primary ? 52 : 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: widget.primary
                    ? Colors.black.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: widget.primary
                      ? Color.lerp(_maroon, _maroonGlow, _glowPulse.value)!
                      : Colors.white.withValues(alpha: 0.22),
                  width: widget.primary ? 1.7 : 1.1,
                ),
                boxShadow: widget.primary
                    ? [
                        BoxShadow(
                          color: _maroonGlow.withValues(alpha: 0.35 * glow),
                          blurRadius: 18 * glow,
                          spreadRadius: 1 * glow,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: widget.primary ? 17 : 15,
                  letterSpacing: widget.primary ? 3 : 2,
                  color: widget.primary
                      ? Colors.white.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.55),
                  shadows: widget.primary
                      ? [
                          Shadow(
                            color: _maroonGlow.withValues(alpha: 0.5 * glow),
                            blurRadius: 8 * glow,
                          ),
                        ]
                      : null,
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
