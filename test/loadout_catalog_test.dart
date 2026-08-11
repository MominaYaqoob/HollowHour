import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/rune_catalog.dart';
import 'package:hollow_hour/game/weapon_catalog.dart';

void main() {
  test('weapon catalog covers all five loadout ids with distinct tradeoffs', () {
    final blade = WeaponCatalog.forId('blade');
    final pistol = WeaponCatalog.forId('pistol');
    final axe = WeaponCatalog.forId('axe');
    final staff = WeaponCatalog.forId('staff');
    final bow = WeaponCatalog.forId('bow');

    expect(pistol.damageMul, 1.0);
    expect(blade.damageMul, greaterThan(pistol.damageMul));
    expect(axe.damageMul, greaterThan(blade.damageMul));
    expect(axe.fireCooldownMul, greaterThan(blade.fireCooldownMul));
    expect(staff.fireCooldownMul, lessThan(pistol.fireCooldownMul));
    expect(bow.aimRangeMul, greaterThan(staff.aimRangeMul));
  });

  test('rune catalog applies vein HP and gale speed', () {
    final both = RuneCatalog.combined({'vein', 'gale'});
    expect(both.maxHp, 18);
    expect(both.moveSpeed, 18);
    expect(both.damage, 0);
  });
}
