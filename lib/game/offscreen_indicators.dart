import 'dart:math' as math;
import 'dart:ui';

/// Screen-edge marker pointing at an off-screen enemy.
class OffscreenEnemyArrow {
  const OffscreenEnemyArrow({
    required this.screenPosition,
    required this.angle,
  });

  /// Position on the visible viewport (camera space).
  final Offset screenPosition;

  /// Radians; 0 points right, matching [atan2] of the enemy direction.
  final double angle;
}

/// Nearest [maxCount] enemies outside the camera, mapped to the closest
/// screen edge so HUD arrows can be painted without walking the full HUD tree.
List<OffscreenEnemyArrow> computeOffscreenEnemyArrows({
  required Offset cameraTopLeft,
  required Size viewSize,
  required Offset playerPosition,
  required Iterable<Offset> enemyPositions,
  int maxCount = 3,
  double edgeInset = 26,
  double onScreenPadding = 12,
}) {
  if (viewSize.isEmpty || maxCount <= 0) return const [];

  final view = Rect.fromLTWH(
    cameraTopLeft.dx,
    cameraTopLeft.dy,
    viewSize.width,
    viewSize.height,
  );
  final visible = view.inflate(onScreenPadding);

  final candidates = <({Offset world, double dist})>[];
  for (final world in enemyPositions) {
    if (visible.contains(world)) continue;
    candidates.add((world: world, dist: (world - playerPosition).distance));
  }
  if (candidates.isEmpty) return const [];
  candidates.sort((a, b) => a.dist.compareTo(b.dist));

  final hw = viewSize.width / 2 - edgeInset;
  final hh = viewSize.height / 2 - edgeInset;
  if (hw <= 4 || hh <= 4) return const [];

  final center = Offset(viewSize.width / 2, viewSize.height / 2);
  final out = <OffscreenEnemyArrow>[];
  for (final c in candidates.take(maxCount)) {
    var dir = (c.world - cameraTopLeft) - center;
    if (dir.distanceSquared < 0.0001) {
      dir = c.world - playerPosition;
    }
    final len = dir.distance;
    if (len < 0.001) continue;
    final nx = dir.dx / len;
    final ny = dir.dy / len;
    final tx = nx.abs() < 1e-6 ? 1e9 : hw / nx.abs();
    final ty = ny.abs() < 1e-6 ? 1e9 : hh / ny.abs();
    final tHit = math.min(tx, ty);
    out.add(
      OffscreenEnemyArrow(
        screenPosition: Offset(center.dx + nx * tHit, center.dy + ny * tHit),
        angle: math.atan2(ny, nx),
      ),
    );
  }
  return out;
}
