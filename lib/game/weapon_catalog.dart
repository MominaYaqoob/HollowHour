/// Combat multipliers for equipped weapons (relative to pistol baseline).
class WeaponStats {
  const WeaponStats({
    required this.id,
    required this.name,
    required this.damageMul,
    required this.fireCooldownMul,
    required this.projectileSpeedMul,
    required this.projectileRadiusMul,
    required this.aimRangeMul,
    required this.shopDescription,
  });

  final String id;
  final String name;

  /// Multiplies talent-adjusted damage.
  final double damageMul;

  /// Multiplies base fire cooldown (higher = slower fire).
  final double fireCooldownMul;
  final double projectileSpeedMul;
  final double projectileRadiusMul;
  final double aimRangeMul;
  final String shopDescription;
}

class WeaponCatalog {
  WeaponCatalog._();

  /// Baseline reference: Ember Pistol (1.0 across the board).
  static const Map<String, WeaponStats> byId = {
    'blade': WeaponStats(
      id: 'blade',
      name: 'Rust Blade',
      damageMul: 1.35,
      fireCooldownMul: 1.40,
      projectileSpeedMul: 0.95,
      projectileRadiusMul: 1.15,
      aimRangeMul: 0.95,
      shopDescription:
          'Heavy close cuts — +35% damage, slower fire.',
    ),
    'pistol': WeaponStats(
      id: 'pistol',
      name: 'Ember Pistol',
      damageMul: 1.0,
      fireCooldownMul: 1.0,
      projectileSpeedMul: 1.0,
      projectileRadiusMul: 1.0,
      aimRangeMul: 1.0,
      shopDescription:
          'Balanced sidearm — standard damage and fire rate.',
    ),
    'axe': WeaponStats(
      id: 'axe',
      name: 'Grave Axe',
      damageMul: 1.55,
      fireCooldownMul: 1.60,
      projectileSpeedMul: 0.90,
      projectileRadiusMul: 1.40,
      aimRangeMul: 0.90,
      shopDescription:
          'Brutal cleave — +55% damage, slowest fire, wider hits.',
    ),
    'staff': WeaponStats(
      id: 'staff',
      name: 'Void Staff',
      damageMul: 0.85,
      fireCooldownMul: 0.72,
      projectileSpeedMul: 1.05,
      projectileRadiusMul: 1.0,
      aimRangeMul: 1.15,
      shopDescription:
          'Quick bolts — −15% damage, much faster fire, more range.',
    ),
    'bow': WeaponStats(
      id: 'bow',
      name: 'Hollow Bow',
      damageMul: 1.15,
      fireCooldownMul: 0.88,
      projectileSpeedMul: 1.20,
      projectileRadiusMul: 0.95,
      aimRangeMul: 1.25,
      shopDescription:
          'Long shots — +15% damage, faster fire, longest range.',
    ),
  };

  static WeaponStats forId(String? id) =>
      byId[id] ?? byId['pistol']!;
}
