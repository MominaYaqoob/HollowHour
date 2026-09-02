import 'dart:math' as math;

/// HP pip math shared by the HUD bar and the critical-health warning.
int hpDamagedIndex({
  required double playerHp,
  required double maxHp,
  int segments = 6,
}) {
  if (playerHp <= 0) return -1;
  final hpRatio = maxHp <= 0 ? 0.0 : (playerHp / maxHp).clamp(0.0, 1.0);
  return math.max(0, (hpRatio * segments).ceil() - 1);
}

/// True when the last 1–2 HP segments remain (same pip count as the HUD HP bar).
bool isHpCritical({
  required double playerHp,
  required double maxHp,
  int segments = 6,
}) {
  final index = hpDamagedIndex(
    playerHp: playerHp,
    maxHp: maxHp,
    segments: segments,
  );
  return index >= 0 && index <= 1;
}
