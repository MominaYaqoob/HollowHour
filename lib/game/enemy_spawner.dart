import 'dart:math' as math;
import 'dart:ui';

import 'enemy.dart';
import 'game_state.dart';

/// Spawns enemies outside the screen edge; rate ramps with time + Hollow Depth.
class EnemySpawner {
  EnemySpawner(this.state, {math.Random? random})
      : _random = random ?? math.Random();

  final GameState state;
  final math.Random _random;

  double _accum = 0;

  /// Base interval at depth 5, t=0: ~2.5s. Depth and elapsed shorten this.
  double get _intervalSeconds {
    final depth = state.hollowDepth.clamp(1, 15);
    // Depth 1 → ~3.2s, depth 5 → ~2.5s, depth 15 → ~1.35s at t=0.
    final depthFactor = 1.15 - (depth - 1) * 0.055;
    final elapsedSec = state.elapsed.inMilliseconds / 1000.0;
    // Every 60s of survival, ~12% faster spawns (floor at 0.55×).
    final timeFactor = math.max(0.55, 1.0 - elapsedSec / 60.0 * 0.12);
    return (2.5 * depthFactor * timeFactor).clamp(0.85, 3.4);
  }

  void update(Duration delta) {
    if (!state.isRunning) return;
    final size = state.worldSize;
    if (size.isEmpty) return;

    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    _accum += dt;
    final interval = _intervalSeconds;
    while (_accum >= interval) {
      _accum -= interval;
      _spawnOne(size);
      // Soft cap so the screen never floods.
      if (state.enemies.length >= 28) break;
    }
  }

  void _spawnOne(Size size) {
    final kind = _pickKind();
    final pos = _edgePoint(size);
    state.enemies.add(EnemyBehavior.spawn(type: kind, position: pos));
  }

  EnemyKind _pickKind() {
    final roll = _random.nextDouble();
    final depth = state.hollowDepth;
    // Higher depth → more tanks & fast pressure.
    if (roll < 0.18 + depth * 0.01) return EnemyKind.tank;
    if (roll < 0.45 + depth * 0.012) return EnemyKind.fast;
    return EnemyKind.ranged;
  }

  Offset _edgePoint(Size size) {
    const margin = 36.0;
    final side = _random.nextInt(4);
    switch (side) {
      case 0: // top
        return Offset(_random.nextDouble() * size.width, -margin);
      case 1: // bottom
        return Offset(_random.nextDouble() * size.width, size.height + margin);
      case 2: // left
        return Offset(-margin, _random.nextDouble() * size.height);
      default: // right
        return Offset(size.width + margin, _random.nextDouble() * size.height);
    }
  }
}
