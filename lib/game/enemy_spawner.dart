import 'dart:math' as math;
import 'dart:ui';

import 'enemy.dart';
import 'game_mode.dart';
import 'game_state.dart';

/// Spawns enemies outside the screen edge; rate ramps with time + Hollow Depth.
class EnemySpawner {
  EnemySpawner(this.state, {math.Random? random})
      : _random = random ?? math.Random();

  final GameState state;
  final math.Random _random;

  double _accum = 0;
  bool _seededFirst = false;

  /// Base interval at depth 5, t=0: ~2.8s. Depth and elapsed shorten this.
  double get _intervalSeconds {
    final depth = state.hollowDepth.clamp(1, 15);
    // Depth 1 → ~3.5s, depth 5 → ~2.8s, depth 15 → ~1.6s at t=0.
    final depthFactor = 1.15 - (depth - 1) * 0.05;
    final elapsedSec = state.elapsed.inMilliseconds / 1000.0;
    // Softer first 90s, then steeper ramp (pairs with enemy speed scale).
    // Easy stages: less calm so Level 1 isn't an empty wait.
    final earlyBonus = elapsedSec < 90
        ? (depth <= 2 ? 1.05 : 1.35)
        : 1.0;
    // Every 60s → ~9% faster spawns after the calm opening.
    final rawTime = 1.0 - math.max(0, elapsedSec - 60) / 60.0 * 0.09;

    if (state.gameMode.isEndless) {
      final timeFactor = math.max(0.15, rawTime);
      return (2.8 * depthFactor * timeFactor * earlyBonus).clamp(0.35, 4.2);
    }

    final timeFactor = math.max(0.58, rawTime);
    final minInterval = depth <= 2 ? 0.85 : 1.0;
    return (2.8 * depthFactor * timeFactor * earlyBonus)
        .clamp(minInterval, 4.2);
  }

  void update(Duration delta) {
    if (!state.isRunning) return;
    final size = state.worldSize;
    if (size.isEmpty) return;

    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    // Level 1 / easy depth: first enemy near the camera within ~1.2s.
    if (!_seededFirst && state.hollowDepth <= 2) {
      _accum += dt;
      if (_accum >= 1.2) {
        _accum = 0;
        _seededFirst = true;
        _spawnOne(size, nearCamera: true);
      }
      return;
    }

    _accum += dt;
    final interval = _intervalSeconds;
    while (_accum >= interval) {
      _accum -= interval;
      _spawnOne(size);
      // Soft cap so the screen never floods.
      if (state.enemies.length >= 19) break;
    }
  }

  void _spawnOne(Size size, {bool nearCamera = false}) {
    final kind = _pickKind();
    final useNear = nearCamera || _shouldSpawnNearCamera();
    final pos = useNear ? _cameraEdgePoint() : _edgePoint(size);
    state.enemies.add(EnemyBehavior.spawn(type: kind, position: pos));
  }

  /// Early / easy stages: spawn just off the visible frame so they enter fast.
  bool _shouldSpawnNearCamera() {
    if (state.viewSize.isEmpty) return false;
    final elapsedSec = state.elapsed.inMilliseconds / 1000.0;
    return state.hollowDepth <= 3 || elapsedSec < 40;
  }

  EnemyKind _pickKind() {
    final roll = _random.nextDouble();
    final depth = state.hollowDepth;
    // Higher depth → more tanks & fast pressure.
    // Easy stages: prefer weaker fast/ranged over tanks.
    if (depth <= 2) {
      if (roll < 0.55) return EnemyKind.fast;
      return EnemyKind.ranged;
    }
    if (roll < 0.18 + depth * 0.01) return EnemyKind.tank;
    if (roll < 0.45 + depth * 0.012) return EnemyKind.fast;
    return EnemyKind.ranged;
  }

  Offset _cameraEdgePoint() {
    final cam = state.cameraTopLeft;
    final view = state.viewSize;
    const margin = 28.0;
    final side = _random.nextInt(4);
    switch (side) {
      case 0: // top
        return Offset(
          cam.dx + _random.nextDouble() * view.width,
          cam.dy - margin,
        );
      case 1: // bottom
        return Offset(
          cam.dx + _random.nextDouble() * view.width,
          cam.dy + view.height + margin,
        );
      case 2: // left
        return Offset(
          cam.dx - margin,
          cam.dy + _random.nextDouble() * view.height,
        );
      default: // right
        return Offset(
          cam.dx + view.width + margin,
          cam.dy + _random.nextDouble() * view.height,
        );
    }
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
