import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/theme/app_assets.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('shop weapon and rune icons exist with real pixels', () async {
    const paths = [
      AppAssets.iconWeaponBlade,
      AppAssets.iconWeaponPistol,
      AppAssets.iconWeaponAxe,
      AppAssets.iconWeaponStaff,
      AppAssets.iconWeaponBow,
      AppAssets.iconRuneVein,
      AppAssets.iconRuneGale,
    ];
    for (final path in paths) {
      final data = await rootBundle.load(path);
      expect(data.lengthInBytes, greaterThan(200), reason: path);
    }
  });
}
