import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/theme/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('enemy idle/walk sheets exist for all kinds', () async {
    for (final kind in AppAssets.gameEnemyKinds) {
      for (final path in [
        AppAssets.gameEnemyIdle(kind),
        AppAssets.gameEnemyWalk(kind),
      ]) {
        final data = await rootBundle.load(path);
        expect(data.lengthInBytes, greaterThan(100), reason: path);
      }
    }
  });

  test('obstacle and pickup sprites exist', () async {
    for (final path in [
      ...AppAssets.gameObstacleAssets,
      AppAssets.gameXpOrb,
      AppAssets.gameMagnet,
    ]) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(50), reason: path);
    }
  });
}
