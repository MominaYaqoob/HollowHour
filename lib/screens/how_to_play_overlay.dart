import 'package:flutter/material.dart';

import '../prefs/app_flags.dart';

/// Dismissible how-to-play overlay — same structural pattern as PauseOverlay.
class HowToPlayOverlay extends StatefulWidget {
  const HowToPlayOverlay({
    super.key,
    required this.visible,
    required this.onDismiss,
    this.persistTutorialFlag = false,
  });

  final bool visible;
  final VoidCallback onDismiss;

  /// When true, marks `hasSeenTutorial` before dismissing (first-match flow).
  final bool persistTutorialFlag;

  @override
  State<HowToPlayOverlay> createState() => _HowToPlayOverlayState();
}

class _HowToPlayOverlayState extends State<HowToPlayOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<double> _panelScale;
  bool _mountedInTree = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _panelScale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOutBack),
    );

    _fadeController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed && mounted) {
        setState(() => _mountedInTree = false);
      }
    });

    if (widget.visible) {
      _mountedInTree = true;
      _fadeController.value = 1;
    }
  }

  @override
  void didUpdateWidget(covariant HowToPlayOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible == oldWidget.visible) return;
    if (widget.visible) {
      setState(() => _mountedInTree = true);
      _fadeController.forward();
    } else {
      _fadeController.reverse();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _gotIt() async {
    if (widget.persistTutorialFlag) {
      await AppFlags.setHasSeenTutorial(true);
    }
    if (!mounted) return;
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    if (!_mountedInTree && !widget.visible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(opacity: _fade.value, child: child);
      },
      child: Material(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Transform.scale(scale: _panelScale.value, child: child);
            },
            child: _HowToPlayPanel(onGotIt: _gotIt),
          ),
        ),
      ),
    );
  }
}

class _HowToPlayPanel extends StatelessWidget {
  const _HowToPlayPanel({required this.onGotIt});

  final VoidCallback onGotIt;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF121010),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _maroon.withValues(alpha: 0.7), width: 1.4),
        boxShadow: [
          BoxShadow(
            color: _maroonGlow.withValues(alpha: 0.22),
            blurRadius: 28,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'How to Survive',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 24,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.92),
              shadows: [
                Shadow(
                  color: _maroonGlow.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Each level is a timed stage. Survive the clock to clear it '
            'and unlock the next. Level 30 frees the next character.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 12,
              height: 1.4,
              letterSpacing: 0.3,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _DiagramBlock(
                  title: 'Move',
                  instruction: 'Use the left stick to walk.',
                  child: const _JoystickDiagram(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DiagramBlock(
                  title: 'Aim & Fire',
                  instruction: 'Hold AIM, drag to aim, release to shoot.',
                  child: const _AimDiagram(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _GotItButton(onTap: onGotIt),
        ],
      ),
    );
  }
}

class _DiagramBlock extends StatelessWidget {
  const _DiagramBlock({
    required this.title,
    required this.instruction,
    required this.child,
  });

  final String title;
  final String instruction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(height: 72, child: Center(child: child)),
          const SizedBox(height: 10),
          Text(
            instruction,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 11,
              height: 1.35,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _JoystickDiagram extends StatelessWidget {
  const _JoystickDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1.5,
              ),
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF8B1A1A).withValues(alpha: 0.7),
              border: Border.all(color: const Color(0xFFC41E1E)),
            ),
          ),
        ],
      ),
    );
  }
}

class _AimDiagram extends StatelessWidget {
  const _AimDiagram();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      height: 64,
      child: CustomPaint(painter: _CrosshairPainter()),
    );
  }
}

class _CrosshairPainter extends CustomPainter {
  static const Color _line = Color(0xFFC41E1E);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = _line.withValues(alpha: 0.85)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final c = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(c, 18, paint);
    canvas.drawCircle(c, 4, paint..style = PaintingStyle.fill);
    paint.style = PaintingStyle.stroke;
    canvas.drawLine(Offset(c.dx, 8), Offset(c.dx, c.dy - 10), paint);
    canvas.drawLine(Offset(c.dx, c.dy + 10), Offset(c.dx, size.height - 8), paint);
    canvas.drawLine(Offset(8, c.dy), Offset(c.dx - 10, c.dy), paint);
    canvas.drawLine(Offset(c.dx + 10, c.dy), Offset(size.width - 8, c.dy), paint);

    // Drag hint arrow.
    final arrow = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(size.width - 6, 14), Offset(size.width - 18, 26), arrow);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _GotItButton extends StatefulWidget {
  const _GotItButton({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_GotItButton> createState() => _GotItButtonState();
}

class _GotItButtonState extends State<_GotItButton>
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
        tween: Tween(begin: 1.0, end: 0.92)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.92, end: 1.06)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1.4,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.06, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.8,
      ),
    ]).animate(_controller);
    _glow = TweenSequence<double>([
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
          final glow = _glow.value;
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: double.infinity,
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Color.lerp(_maroon, _maroonGlow, glow)!,
                  width: 1.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _maroonGlow.withValues(alpha: 0.35 * glow),
                    blurRadius: 16 * glow,
                  ),
                ],
              ),
              child: Text(
                'Got it',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  letterSpacing: 3,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
