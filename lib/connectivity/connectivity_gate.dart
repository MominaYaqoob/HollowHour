import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

/// Top-level connectivity wrapper — overlays a blocking offline screen without
/// navigating away or disposing the [child] tree underneath.
class ConnectivityGate extends StatefulWidget {
  const ConnectivityGate({super.key, required this.child});

  final Widget child;

  @override
  State<ConnectivityGate> createState() => _ConnectivityGateState();
}

class _ConnectivityGateState extends State<ConnectivityGate> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  /// null = still resolving first check; then true/false.
  bool? _online;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    unawaited(_refresh());
    _subscription =
        _connectivity.onConnectivityChanged.listen(_applyResults);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  bool _hasLink(List<ConnectivityResult> results) => results.hasConnectivity;

  void _applyResults(List<ConnectivityResult> results) {
    final online = _hasLink(results);
    if (!mounted) return;
    if (_online == online) return;
    setState(() => _online = online);
  }

  Future<void> _refresh() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _applyResults(results);
    } catch (e, st) {
      debugPrint('Connectivity check failed: $e\n$st');
      // Fail closed — block until we can confirm a link.
      if (mounted && _online != false) {
        setState(() => _online = false);
      }
    }
  }

  Future<void> _onRetry() async {
    if (_retrying) return;
    setState(() => _retrying = true);
    await _refresh();
    if (mounted) setState(() => _retrying = false);
  }

  @override
  Widget build(BuildContext context) {
    final blocked = _online == false;

    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        if (blocked) _OfflineBlocker(onRetry: _onRetry, retrying: _retrying),
      ],
    );
  }
}

/// Full-screen, non-dismissible offline cover (absorbs all pointer events).
class _OfflineBlocker extends StatelessWidget {
  const _OfflineBlocker({
    required this.onRetry,
    required this.retrying,
  });

  final VoidCallback onRetry;
  final bool retrying;

  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _charcoal,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.wifi_off_rounded,
                size: 72,
                color: _maroon.withValues(alpha: 0.95),
                shadows: [
                  Shadow(
                    color: _maroonGlow.withValues(alpha: 0.45),
                    blurRadius: 22,
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'No Internet Connection',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: Colors.white.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      color: _maroonGlow.withValues(alpha: 0.4),
                      blurRadius: 16,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Hollow Hour requires an active connection to continue.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 14,
                  height: 1.45,
                  letterSpacing: 0.4,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
              ),
              const Spacer(flex: 2),
              _RetryButton(onTap: onRetry, busy: retrying),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

class _RetryButton extends StatefulWidget {
  const _RetryButton({required this.onTap, required this.busy});

  final VoidCallback onTap;
  final bool busy;

  @override
  State<_RetryButton> createState() => _RetryButtonState();
}

class _RetryButtonState extends State<_RetryButton>
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
    if (widget.busy) return;
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
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Color.lerp(_maroon, _maroonGlow, _glowPulse.value)!,
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
              child: widget.busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: _maroonGlow,
                      ),
                    )
                  : Text(
                      'Retry',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 17,
                        letterSpacing: 3,
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
