import 'dart:math' as math;
import 'dart:ui';

import 'game_state.dart';

/// Moves the player from the existing bottom-left joystick drag vector.
class PlayerController {
  PlayerController(this.state);

  final GameState state;

  /// Normalized stick vector in [-1, 1], length capped at 1.
  Offset stick = Offset.zero;

  void setStickFromLocalDelta(Offset localDelta, double outerRadius) {
    if (outerRadius <= 0) {
      stick = Offset.zero;
      return;
    }
    final clamped = Offset(
      (localDelta.dx / outerRadius).clamp(-1.0, 1.0),
      (localDelta.dy / outerRadius).clamp(-1.0, 1.0),
    );
    final len = clamped.distance;
    stick = len > 1 ? clamped / len : clamped;
  }

  void clearStick() => stick = Offset.zero;

  void update(Duration delta) {
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    // Idle immediately when stick released — no skate/hold on last walk frame.
    if (!state.isRunning || stick == Offset.zero) {
      state.playerMoving = false;
      state.walkAnimTime = 0;
      return;
    }

    final size = state.worldSize;
    if (size.isEmpty) return;

    state.playerMoving = true;
    if (!state.aimFacingActive) {
      state.facingAngle = math.atan2(stick.dy, stick.dx);
    }

    const playerRadius = 14.0;
    final before = state.playerPosition;
    final next = state.playerPosition + stick * state.moveSpeed * dt;
    final resolved = GameState.resolveObstacleCollision(
      next,
      playerRadius,
      state.obstacles,
    );
    state.playerPosition = Offset(
      resolved.dx.clamp(playerRadius, size.width - playerRadius),
      resolved.dy.clamp(playerRadius, size.height - playerRadius),
    );

    // Advance walk cycle from actual displacement so frames match speed;
    // stuck against a wall → idle feet (no treadmill skate).
    final moved = (state.playerPosition - before).distance;
    if (moved < 0.15) {
      state.playerMoving = false;
      state.walkAnimTime = 0;
      return;
    }
    // ~8fps at base 175 speed / full stick; scales with effective speed.
    const baseSpeed = 175.0;
    final speedScale =
        (moved / dt / baseSpeed).clamp(0.35, 1.75);
    state.walkAnimTime += dt * speedScale;
  }

  /// Visual knuckle offset inside the joystick (pixels).
  Offset knuckleOffset(double maxTravel) {
    final len = stick.distance;
    if (len == 0) return Offset.zero;
    final capped = math.min(len, 1.0);
    return stick / len * capped * maxTravel;
  }
}
