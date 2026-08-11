/// Passive bonuses from equipped runes (applied on match start).
class RuneStats {
  const RuneStats({
    required this.id,
    required this.name,
    this.maxHpBonus = 0,
    this.moveSpeedBonus = 0,
    this.damageBonus = 0,
    required this.shopDescription,
  });

  final String id;
  final String name;
  final double maxHpBonus;
  final double moveSpeedBonus;
  final double damageBonus;
  final String shopDescription;
}

class RuneCatalog {
  RuneCatalog._();

  static const Map<String, RuneStats> byId = {
    'vein': RuneStats(
      id: 'vein',
      name: 'Vein Rune',
      maxHpBonus: 18,
      shopDescription: 'Increases maximum HP by 18.',
    ),
    'gale': RuneStats(
      id: 'gale',
      name: 'Gale Rune',
      moveSpeedBonus: 18,
      shopDescription: 'Increases move speed by 18.',
    ),
  };

  static RuneStats? forId(String id) => byId[id];

  /// Sum bonuses for every equipped rune id.
  static ({double maxHp, double moveSpeed, double damage}) combined(
    Iterable<String> equippedIds,
  ) {
    var maxHp = 0.0;
    var moveSpeed = 0.0;
    var damage = 0.0;
    for (final id in equippedIds) {
      final r = byId[id];
      if (r == null) continue;
      maxHp += r.maxHpBonus;
      moveSpeed += r.moveSpeedBonus;
      damage += r.damageBonus;
    }
    return (maxHp: maxHp, moveSpeed: moveSpeed, damage: damage);
  }
}
