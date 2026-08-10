import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/theme/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('equipped character ids resolve to existing game player sprites', () async {
    for (final id in AppAssets.gamePlayerIds) {
      for (final facing in ['down', 'side', 'up']) {
        final idle = AppAssets.gamePlayerIdle(id, facing: facing);
        final walk = AppAssets.gamePlayerWalk(id, facing: facing);
        final idleData = await rootBundle.load(idle);
        final walkData = await rootBundle.load(walk);
        expect(idleData.lengthInBytes, greaterThan(100), reason: idle);
        expect(walkData.lengthInBytes, greaterThan(100), reason: walk);
      }
      // Same id mapping as Character Select / Prepare portraits.
      final portrait = AppAssets.characterPortrait(id);
      final portraitData = await rootBundle.load(portrait);
      expect(portraitData.lengthInBytes, greaterThan(100), reason: portrait);
    }
  });
}
