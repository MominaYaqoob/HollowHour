import 'dart:ui';

import 'game_state.dart';

export 'game_state.dart' show EnemyEntity, EnemyKind;

/// Factory + per-tick chase behavior for [EnemyEntity].
class EnemyBehavior {
  EnemyBehavior._();

  static EnemyEntity spawn({
    required EnemyKind type,
    required Offset position,
  }) {
    switch (type) {
      case EnemyKind.fast:
        // Fast / weak — dies quickly, pressure with speed.
        return EnemyEntity(
          position: position,
          hp: 14,
          maxHp: 14,
          speed: 98,
          damage: 6,
          radius: 11,
          type: type,
        );
      case EnemyKind.tank:
        // Slow / tanky.
        return EnemyEntity(
          position: position,
          hp: 70,
          maxHp: 70,
          speed: 38,
          damage: 14,
          radius: 20,
          type: type,
        );
      case EnemyKind.ranged:
        // Basic "ranged" silhouette — still chases; mid stats.
        return EnemyEntity(
          position: position,
          hp: 28,
          maxHp: 28,
          speed: 58,
          damage: 9,
          radius: 14,
          type: type,
        );
    }
  }

  static void tickAll(GameState state, Duration delta) {
    if (!state.isRunning) return;
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    final player = state.playerPosition;
    for (final e in state.enemies) {
      final toPlayer = player - e.position;
      final dist = toPlayer.distance;
      if (dist < 0.5) {
        e.moving = false;
        continue;
      }
      e.moving = true;
      e.facingLeft = toPlayer.dx < 0;
      e.walkAnimTime += dt;
      final next = e.position + toPlayer / dist * e.speed * dt;
      e.position = GameState.resolveObstacleCollision(
        next,
        e.radius,
        state.obstacles,
      );
    }
  }
}
