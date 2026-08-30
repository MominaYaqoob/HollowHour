import 'package:flutter/material.dart';

import 'app_assets.dart';

/// Branding art sized to the phone screen, with square JPEG corners faded out.
class BrandedHeroMark extends StatelessWidget {
  const BrandedHeroMark({
    super.key,
    this.widthFactor = 0.54,
    this.heightFactor = 0.30,
    this.glowStrength = 0.35,
    this.errorBuilder,
  });

  /// Max width as a fraction of the screen.
  final double widthFactor;

  /// Max height as a fraction of the screen.
  final double heightFactor;

  final double glowStrength;
  final ImageErrorWidgetBuilder? errorBuilder;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final side = (size.width * widthFactor)
        .clamp(96.0, size.height * heightFactor)
        .toDouble();
    final glow = glowStrength.clamp(0.0, 1.0);

    return SizedBox(
      width: side,
      height: side,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _maroonGlow.withValues(alpha: 0.12 + glow * 0.10),
                    Colors.transparent,
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
          ),
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) {
              return RadialGradient(
                center: const Alignment(0, 0.08),
                radius: 0.82,
                colors: const [
                  Color(0xFFFFFFFF),
                  Color(0xFFFFFFFF),
                  Color(0xB3FFFFFF),
                  Color(0x00FFFFFF),
                ],
                stops: const [0.0, 0.50, 0.70, 1.0],
              ).createShader(bounds);
            },
            child: Transform.scale(
              scale: 1.06,
              child: Image.asset(
                AppAssets.brandingLogo,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: errorBuilder ??
                    (_, _, _) => const SizedBox.shrink(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
