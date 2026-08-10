import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/aim_fire_controller.dart';
import 'package:hollow_hour/game/game_state.dart';
import 'package:hollow_hour/game/magnet_spawner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('obstacles spawn 4–6 on first world size', () {
    final state = GameState();
    state.setWorldSize(const Size(400, 700));
    expect(state.obstacles.length, inInclusiveRange(4, 6));
    expect(state.playerPosition, const Offset(200, 350));
  });

  test('obstacle collision pushes point outside radius', () {
    final obstacles = [
      ObstacleEntity(
        position: const Offset(100, 100),
        radius: 20,
        assetPath: 'x',
        drawWidth: 40,
        drawHeight: 40,
      ),
    ];
    final resolved = GameState.resolveObstacleCollision(
      const Offset(105, 100),
      10,
      obstacles,
    );
    expect((resolved - const Offset(100, 100)).distance, closeTo(30, 0.01));
  });

  test('magazine starts at 6 and reload refills after 1.2s', () {
    final state = GameState();
    expect(state.currentAmmo, 6);
    expect(state.maxAmmo, 6);
    expect(GameState.reloadDurationSeconds, 1.2);

    // Simulate empty magazine entering reload (same path AimFireController uses).
    state.currentAmmo = 0;
    state.isReloading = true;
    state.reloadTimer = GameState.reloadDurationSeconds;

    final aim = AimFireController(state);
    aim.update(const Duration(milliseconds: 600));
    expect(state.isReloading, isTrue);
    expect(state.currentAmmo, 0);

    aim.update(const Duration(milliseconds: 700));
    expect(state.isReloading, isFalse);
    expect(state.currentAmmo, 6);
  });

  test('aim range indicator fades toward active while aiming', () {
    final state = GameState()..setWorldSize(const Size(300, 300));
    final aim = AimFireController(state);
    expect(aim.rangeIndicatorAlpha, 0);

    aim.onPanStart(const Offset(40, 0), 48);
    expect(aim.isAiming, isTrue);
    aim.update(const Duration(milliseconds: 200));
    expect(aim.rangeIndicatorAlpha, greaterThan(0));

    // Release without firing (zero aim) — clear drag.
    aim.onPanUpdate(Offset.zero, 48);
    // Force idle fade-out path.
    aim.onPanEnd();
    expect(aim.isAiming, isFalse);
    for (var i = 0; i < 10; i++) {
      aim.update(const Duration(milliseconds: 50));
    }
    expect(aim.rangeIndicatorAlpha, lessThan(0.05));
  });

  test('magnet activate sets timed magnetActive flag', () {
    final state = GameState()..setWorldSize(const Size(400, 700));
    final magnet = MagnetSpawner(state);
    magnet.activateFromPickup();
    expect(state.magnetActive, isTrue);
    expect(state.magnetTimeLeft, inInclusiveRange(8, 10));
    expect(state.lastPickupLabel, 'MAGNET');
  });
}
