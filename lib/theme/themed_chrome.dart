import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import 'app_assets.dart';

/// Themed UI icon from the Hollow Hour asset pack.
/// Falls back to a maroon Material icon if the asset fails to load.
class ThemedUiIcon extends StatelessWidget {
  const ThemedUiIcon(
    this.asset, {
    super.key,
    this.size = 20,
    this.color = const Color(0xFFC41E1E),
  });

  final String asset;
  final double size;
  final Color color;

  IconData get _fallbackIcon {
    switch (asset) {
      case AppAssets.iconEmbers:
        return Icons.local_fire_department;
      case AppAssets.iconSettings:
        return Icons.settings_outlined;
      case AppAssets.iconShop:
        return Icons.storefront_outlined;
      case AppAssets.iconLock:
        return Icons.lock_outline;
      case AppAssets.iconHp:
        return Icons.favorite;
      case AppAssets.iconPause:
        return Icons.pause;
      default:
        return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      errorBuilder: (_, _, _) => Icon(
        _fallbackIcon,
        size: size,
        color: color,
      ),
    );
  }
}

/// Compact Embers balance used in screen headers.
class EmberBalanceChip extends StatelessWidget {
  const EmberBalanceChip({
    super.key,
    required this.amount,
    this.compact = false,
  });

  final int amount;
  final bool compact;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final iconSize = compact ? 16.0 : 18.0;
    return Container(
      padding: EdgeInsets.fromLTRB(compact ? 8 : 10, 5, compact ? 10 : 12, 5),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _maroon.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: _maroonGlow.withValues(alpha: 0.18),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ThemedUiIcon(AppAssets.iconEmbers, size: iconSize),
          SizedBox(width: compact ? 5 : 7),
          Text(
            compact ? '$amount' : 'Embers: $amount',
            style: TextStyle(
              fontFamily: compact ? 'monospace' : 'serif',
              fontSize: compact ? 13 : 13.5,
              letterSpacing: compact ? 0.6 : 1.0,
              fontWeight: compact ? FontWeight.w600 : FontWeight.w400,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
        ],
      ),
    );
  }
}

/// Serif back chevron — no Material Icons in headers.
class ThemedBackButton extends StatelessWidget {
  const ThemedBackButton({
    super.key,
    required this.onPressed,
  });

  final VoidCallback onPressed;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {
        AudioManager.instance.playTap();
        onPressed();
      },
      splashRadius: 22,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
      icon: Text(
        '←',
        style: TextStyle(
          fontFamily: 'serif',
          fontSize: 26,
          height: 1,
          color: _maroonGlow.withValues(alpha: 0.92),
          shadows: [
            Shadow(
              color: _maroonGlow.withValues(alpha: 0.35),
              blurRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
