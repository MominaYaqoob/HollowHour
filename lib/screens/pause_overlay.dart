import 'package:flutter/material.dart';

/// Semi-transparent pause overlay for gameplay — fades in/out when [visible].
class PauseOverlay extends StatefulWidget {
  const PauseOverlay({
    super.key,
    required this.visible,
    required this.onResume,
    required this.onRestart,
    required this.onQuitToMenu,
    this.timeSurvived = '04:12',
    this.kills = 23,
    this.level = 5,
  });

  final bool visible;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuitToMenu;
  final String timeSurvived;
  final int kills;
  final int level;

  @override
  State<PauseOverlay> createState() => _PauseOverlayState();
}

class _PauseOverlayState extends State<PauseOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<double> _panelScale;

  /// Keeps the widget in the tree while fading out.
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
  void didUpdateWidget(covariant PauseOverlay oldWidget) {
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

  @override
  Widget build(BuildContext context) {
    if (!_mountedInTree && !widget.visible) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _fadeController,
      builder: (context, child) {
        return Opacity(
          opacity: _fade.value,
          child: child,
        );
      },
      child: Material(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              return Transform.scale(
                scale: _panelScale.value,
                child: child,
              );
            },
            child: _PausePanel(
              timeSurvived: widget.timeSurvived,
              kills: widget.kills,
              level: widget.level,
              onResume: widget.onResume,
              onRestart: widget.onRestart,
              onQuitToMenu: widget.onQuitToMenu,
            ),
          ),
        ),
      ),
    );
  }
}

class _PausePanel extends StatelessWidget {
  const _PausePanel({
    required this.timeSurvived,
    required this.kills,
    required this.level,
    required this.onResume,
    required this.onRestart,
    required this.onQuitToMenu,
  });

  final String timeSurvived;
  final int kills;
  final int level;
  final VoidCallback onResume;
  final VoidCallback onRestart;
  final VoidCallback onQuitToMenu;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF121010),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _maroon.withValues(alpha: 0.7),
          width: 1.4,
        ),
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
            'Paused',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 28,
              letterSpacing: 4,
              color: Colors.white.withValues(alpha: 0.92),
              shadows: [
                Shadow(
                  color: _maroonGlow.withValues(alpha: 0.45),
                  blurRadius: 12,
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          _PauseButton(
            label: 'Resume',
            primary: true,
            onTap: onResume,
          ),
          const SizedBox(height: 12),
          _PauseButton(
            label: 'Restart',
            onTap: onRestart,
          ),
          const SizedBox(height: 12),
          _PauseButton(
            label: 'Quit to Menu',
            onTap: onQuitToMenu,
          ),
          const SizedBox(height: 22),
          Text(
            'Time Survived: $timeSurvived  ·  Kills: $kills  ·  Level: $level',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 11,
              letterSpacing: 0.6,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _PauseButton extends StatefulWidget {
  const _PauseButton({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_PauseButton> createState() => _PauseButtonState();
}

class _PauseButtonState extends State<_PauseButton>
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
          final glow = _glowPulse.value;
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: double.infinity,
              height: widget.primary ? 48 : 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Color.lerp(
                    _maroon.withValues(alpha: widget.primary ? 0.75 : 0.45),
                    _maroonGlow,
                    glow,
                  )!,
                  width: widget.primary ? 1.6 : 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _maroonGlow.withValues(
                      alpha: (widget.primary ? 0.35 : 0.2) * glow,
                    ),
                    blurRadius: (widget.primary ? 16 : 12) * glow,
                    spreadRadius: (widget.primary ? 1.0 : 0.4) * glow,
                  ),
                ],
              ),
              child: Text(
                widget.label,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: widget.primary ? 16 : 14,
                  letterSpacing: widget.primary ? 3 : 2,
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.88),
                    const Color(0xFFFFE8E8),
                    glow * 0.4,
                  ),
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
