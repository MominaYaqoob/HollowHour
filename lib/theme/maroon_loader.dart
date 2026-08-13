import 'package:flutter/material.dart';

/// Shared maroon spinner used for brief gates (boot / level / ads).
class MaroonLoader extends StatelessWidget {
  const MaroonLoader({super.key, this.size = 36, this.strokeWidth = 3});

  final double size;
  final double strokeWidth;

  static const Color maroon = Color(0xFF8B1A1A);
  static const Color maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        color: maroonGlow,
        backgroundColor: maroon.withValues(alpha: 0.25),
      ),
    );
  }
}

/// Full-screen boot / gate scaffold.
class MaroonLoaderScaffold extends StatelessWidget {
  const MaroonLoaderScaffold({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: MaroonLoaderOverlay(message: message),
    );
  }
}

/// Modal barrier + maroon spinner (blocks taps while visible).
class MaroonLoaderOverlay extends StatelessWidget {
  const MaroonLoaderOverlay({
    super.key,
    this.message,
    this.opaque = true,
  });

  final String? message;
  final bool opaque;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: opaque
            ? const Color(0xFF0A0A0A).withValues(alpha: 0.82)
            : Colors.black.withValues(alpha: 0.55),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MaroonLoader(),
              if (message != null && message!.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text(
                  message!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.72),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
