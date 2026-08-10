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
    if (!state.isRunning || stick == Offset.zero) return;
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    final size = state.worldSize;
    if (size.isEmpty) return;

    const playerRadius = 14.0;
    final next = state.playerPosition + stick * state.moveSpeed * dt;
    state.playerPosition = Offset(
      next.dx.clamp(playerRadius, size.width - playerRadius),
      next.dy.clamp(playerRadius, size.height - playerRadius),
    );
  }

  /// Visual knuckle offset inside the joystick (pixels).
  Offset knuckleOffset(double maxTravel) {
    final len = stick.distance;
    if (len == 0) return Offset.zero;
    final capped = math.min(len, 1.0);
    return stick / len * capped * maxTravel;
  }
}
