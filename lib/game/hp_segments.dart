import 'dart:math' as math;

/// HP pip math shared by the HUD bar and the critical-health warning.
int hpDamagedIndex({
  required double playerHp,
  required double maxHp,
  int segments = 3,
}) {
  if (playerHp <= 0) return -1;
  final hpRatio = maxHp <= 0 ? 0.0 : (playerHp / maxHp).clamp(0.0, 1.0);
  return math.max(0, (hpRatio * segments).ceil() - 1);
}

/// True when only the last pip (3-seg bar) or last 1–2 pips (longer bars) remain.
bool isHpCritical({
  required double playerHp,
  required double maxHp,
  int segments = 3,
}) {
  final index = hpDamagedIndex(
    playerHp: playerHp,
    maxHp: maxHp,
    segments: segments,
  );
  final criticalMaxIndex = segments <= 3 ? 0 : 1;
  return index >= 0 && index <= criticalMaxIndex;
}
