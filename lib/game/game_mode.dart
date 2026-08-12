/// Internal match clock kind. Player-facing Mode picker removed — stages own duration.
enum GameMode { standard, quick, endless }

extension GameModeDuration on GameMode {
  /// Fallback durations (stage runs pass explicit [matchDuration] instead).
  Duration get matchDuration => switch (this) {
        GameMode.standard => const Duration(minutes: 20),
        GameMode.quick => const Duration(minutes: 10),
        GameMode.endless => Duration.zero,
      };

  bool get isEndless => this == GameMode.endless;

  /// Legacy step used by [GameState.survivalLevelReached] for endless/time maps.
  static const Duration standardLevelInterval = Duration(seconds: 40);
}

/// Character campaign: Level 1 ≈ 1:00 … Level 30 = 15:00.
Duration stageDurationForLevel(int level) {
  final n = level.clamp(1, 30);
  final minutes = 1.0 + 14.0 * (n - 1) / 29.0;
  return Duration(milliseconds: (minutes * 60000).round());
}

/// Maps stage level 1–30 onto former Hollow Depth 1–15 for spawn pressure.
int stageDepthForLevel(int level) {
  final n = level.clamp(1, 30);
  return (1 + (14 * (n - 1) / 29)).round().clamp(1, 15);
}

/// Enemy HP/damage multiplier for early stages only.
/// Level 3+ returns 1.0 so difficulty matches pre-scaling behavior.
double stageEnemyStatScale(int level) {
  final n = level.clamp(1, 30);
  if (n <= 1) return 0.6;
  if (n == 2) return 0.75;
  return 1.0;
}

String stageDurationLabel(int level) {
  final d = stageDurationForLevel(level);
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  if (s == 0) return '${m}m';
  return '$m:${s.toString().padLeft(2, '0')}';
}
