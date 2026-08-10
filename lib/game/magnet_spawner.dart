import 'dart:math' as math;
import 'dart:ui';

import 'game_state.dart';

/// Spawns magnet pickups every 20–30s and ticks active magnet duration.
class MagnetSpawner {
  MagnetSpawner(this.state) {
    _scheduleNext();
  }

  final GameState state;
  final math.Random _rng = math.Random();

  void _scheduleNext() {
    // 20–30 seconds between spawns.
    state.magnetSpawnTimer = 20 + _rng.nextDouble() * 10;
    state.magnetSpawnArmed = true;
  }

  void update(Duration delta) {
    if (!state.isRunning) return;
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    if (state.magnetActive) {
      state.magnetTimeLeft -= dt;
      if (state.magnetTimeLeft <= 0) {
        state.magnetTimeLeft = 0;
        state.magnetActive = false;
      }
    }

    if (!state.magnetSpawnArmed) {
      _scheduleNext();
    }

    state.magnetSpawnTimer -= dt;
    if (state.magnetSpawnTimer > 0) return;

    _spawnPickup();
    _scheduleNext();
  }

  void _spawnPickup() {
    final size = state.worldSize;
    if (size.isEmpty) return;

    // Prefer a free on-screen spot away from the player.
    for (var i = 0; i < 24; i++) {
      final pos = Offset(
        36 + _rng.nextDouble() * (size.width - 72),
        36 + _rng.nextDouble() * (size.height - 72),
      );
      if ((pos - state.playerPosition).distance < 70) continue;
      var blocked = false;
      for (final o in state.obstacles) {
        if ((pos - o.position).distance < o.radius + 20) {
          blocked = true;
          break;
        }
      }
      if (blocked) continue;
      state.magnetPickups
        ..clear()
        ..add(MagnetPickupEntity(position: pos));
      return;
    }

    state.magnetPickups
      ..clear()
      ..add(
        MagnetPickupEntity(
          position: Offset(size.width * 0.2, size.height * 0.25),
        ),
      );
  }

  /// Activate magnet for 8–10 seconds on pickup.
  void activateFromPickup() {
    state.magnetActive = true;
    state.magnetTimeLeft = 8 + _rng.nextDouble() * 2;
    state.magnetPickups.clear();
    state.notePickup('MAGNET');
  }
}
