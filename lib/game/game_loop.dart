import 'package:flutter/scheduler.dart';

import 'aim_fire_controller.dart';
import 'collision_service.dart';
import 'enemy.dart';
import 'enemy_spawner.dart';
import 'game_state.dart';
import 'player_controller.dart';

typedef GameEndCallback = void Function({
  required bool won,
  required int killCount,
  required String timeLabel,
  required int embersEarned,
});

/// Ticker-driven ~60fps match loop.
class GameLoop {
  GameLoop({
    required this.state,
    required TickerProvider vsync,
    this.onPlayerDamaged,
    this.onLevelUp,
    this.onEnded,
  })  : player = PlayerController(state),
        aim = AimFireController(state),
        spawner = EnemySpawner(state),
        collision = CollisionService(state) {
    _ticker = vsync.createTicker(_onTick);
  }

  final GameState state;
  final PlayerController player;
  final AimFireController aim;
  final EnemySpawner spawner;
  final CollisionService collision;

  final void Function()? onPlayerDamaged;
  final void Function()? onLevelUp;
  final GameEndCallback? onEnded;

  late final Ticker _ticker;
  Duration _last = Duration.zero;
  bool _started = false;
  bool _endedDispatched = false;
  bool _wasAwaitingLevelUp = false;

  void start() {
    if (_started) return;
    _started = true;
    _last = Duration.zero;
    _ticker.start();
  }

  void stop() {
    if (_ticker.isActive) _ticker.stop();
    _started = false;
  }

  void dispose() {
    stop();
    _ticker.dispose();
  }

  void _onTick(Duration elapsed) {
    final delta =
        _last == Duration.zero ? Duration.zero : elapsed - _last;
    _last = elapsed;

    // Cap spiral-of-death after a hitch (~33ms).
    final clamped = delta > const Duration(milliseconds: 33)
        ? const Duration(milliseconds: 33)
        : delta;

    if (state.isRunning && clamped > Duration.zero) {
      player.update(clamped);
      aim.update(clamped);
      EnemyBehavior.tickAll(state, clamped);
      spawner.update(clamped);
      collision.update(clamped, onPlayerDamaged: onPlayerDamaged);
      state.tick(clamped);
    } else {
      state.markDirty();
    }

    if (state.awaitingLevelUp && !_wasAwaitingLevelUp) {
      _wasAwaitingLevelUp = true;
      onLevelUp?.call();
    } else if (!state.awaitingLevelUp) {
      _wasAwaitingLevelUp = false;
    }

    if (!_endedDispatched && (state.isGameOver || state.isWin)) {
      _endedDispatched = true;
      stop();
      final won = state.isWin;
      final embers = state.embersEarned + (won ? 40 : 0);
      onEnded?.call(
        won: won,
        killCount: state.killCount,
        timeLabel: state.elapsedLabel,
        embersEarned: embers,
      );
    }
  }
}
