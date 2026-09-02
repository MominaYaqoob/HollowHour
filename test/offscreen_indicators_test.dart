import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/offscreen_indicators.dart';

void main() {
  const cam = Offset.zero;
  const view = Size(200, 200);
  const player = Offset(100, 100);

  test('on-screen enemies produce no arrows', () {
    final arrows = computeOffscreenEnemyArrows(
      cameraTopLeft: cam,
      viewSize: view,
      playerPosition: player,
      enemyPositions: const [Offset(110, 110), Offset(40, 40)],
    );
    expect(arrows, isEmpty);
  });

  test('off-screen enemy maps to the nearest edge', () {
    final arrows = computeOffscreenEnemyArrows(
      cameraTopLeft: cam,
      viewSize: view,
      playerPosition: player,
      enemyPositions: const [Offset(-80, 100)],
    );
    expect(arrows, hasLength(1));
    expect(arrows.first.screenPosition.dx, lessThan(30));
    expect(arrows.first.screenPosition.dy, closeTo(100, 1));
  });

  test('keeps the nearest 3 off-screen enemies', () {
    final arrows = computeOffscreenEnemyArrows(
      cameraTopLeft: cam,
      viewSize: view,
      playerPosition: player,
      enemyPositions: const [
        Offset(-40, 100),
        Offset(400, 100),
        Offset(100, -50),
        Offset(100, 500),
        Offset(-200, -200),
      ],
    );
    expect(arrows, hasLength(3));
  });
}
