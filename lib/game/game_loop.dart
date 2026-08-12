import 'package:flutter/scheduler.dart';

import 'aim_fire_controller.dart';
import 'collision_service.dart';
import 'enemy.dart';
import 'enemy_spawner.dart';
import 'game_state.dart';
import 'magnet_spawner.dart';
import 'player_controller.dart';

typedef GameEndCallback = void Function({
  required bool won,
  required int killCount,
  required String timeLabel,
  required int embersEarned,
  required int levelReached,
  required bool canRevive,
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
        magnet = MagnetSpawner(state),
        collision = CollisionService(state) {
    collision.magnetSpawner = magnet;
    _ticker = vsync.createTicker(_onTick);
  }

  final GameState state;
  final PlayerController player;
  final AimFireController aim;
  final EnemySpawner spawner;
  final MagnetSpawner magnet;
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
      magnet.update(clamped);
      collision.update(clamped, onPlayerDamaged: onPlayerDamaged);
      state.tick(clamped);
    }
    // When paused / level-up / ended: do NOT markDirty every frame — that was
    // repainting the full arena ~60fps for no gameplay change (major hitch source).

    if (state.awaitingLevelUp && !_wasAwaitingLevelUp) {
      _wasAwaitingLevelUp = true;
      onLevelUp?.call();
    } else if (!state.awaitingLevelUp) {
      _wasAwaitingLevelUp = false;
    }

    if (!_endedDispatched && state.isWin) {
      _dispatchEnded(won: true, canRevive: false);
      return;
    }

    // First death: stop and surface GameOver with revive offer — do not treat
    // as a final end until revive is declined or already offered this run.
    if (!_endedDispatched && state.isGameOver) {
      if (!state.reviveOfferedThisRun) {
        state.markReviveOffered();
        _dispatchEnded(won: false, canRevive: true);
        return;
      }
      _dispatchEnded(won: false, canRevive: false);
    }
  }

  void _dispatchEnded({required bool won, required bool canRevive}) {
    _endedDispatched = true;
    stop();
    final embers = state.embersEarned + (won ? 40 : 0);
    final killCount = state.killCount;
    final timeLabel = state.elapsedLabel;
    final levelReached = state.survivalLevelReached;
    // Navigate after this frame — avoid pushing routes mid-ticker tick.
    SchedulerBinding.instance.addPostFrameCallback((_) {
      onEnded?.call(
        won: won,
        killCount: killCount,
        timeLabel: timeLabel,
        embersEarned: embers,
        levelReached: levelReached,
        canRevive: canRevive,
      );
    });
  }

  /// Restarts the ticker after a successful revive.
  void resumeAfterRevive() {
    _endedDispatched = false;
    _last = Duration.zero;
    if (!_ticker.isActive) {
      _started = true;
      _ticker.start();
    }
  }
}
