import 'package:flutter/material.dart';

import 'app_assets.dart';

/// Dark field background + optional fog texture.
class FieldBackdrop extends StatelessWidget {
  const FieldBackdrop({
    super.key,
    this.showField = true,
    this.showFogTexture = true,
    this.fieldOpacity = 0.85,
    this.fogOpacity = 0.18,
  });

  final bool showField;
  final bool showFogTexture;
  final double fieldOpacity;
  final double fogOpacity;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0A0A0A)),
          if (showField)
            Opacity(
              opacity: fieldOpacity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    AppAssets.bgField,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.72),
                          Colors.black.withValues(alpha: 0.45),
                          Colors.black.withValues(alpha: 0.8),
                        ],
                      ),
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.1,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.65),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (showFogTexture)
            Opacity(
              opacity: fogOpacity,
              child: Image.asset(
                AppAssets.bgFog,
                fit: BoxFit.cover,
                color: Colors.white,
                colorBlendMode: BlendMode.modulate,
                errorBuilder: (_, _, _) => const SizedBox.shrink(),
              ),
            ),
        ],
      ),
    );
  }
}
