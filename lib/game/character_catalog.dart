/// Roster stats and unlock prices — single source for Shop and Character Select.
class CharacterStats {
  const CharacterStats({
    required this.id,
    required this.name,
    required this.hp,
    required this.speed,
    this.costEmbers = 0,
  });

  final String id;
  final String name;
  final int hp;
  final int speed;

  /// Embers to unlock. `0` means starter (Wanderer).
  final int costEmbers;
}

class CharacterCatalog {
  CharacterCatalog._();

  static const Map<String, CharacterStats> byId = {
    'wanderer': CharacterStats(
      id: 'wanderer',
      name: 'Wanderer',
      hp: 120,
      speed: 8,
    ),
    'huntress': CharacterStats(
      id: 'huntress',
      name: 'Huntress',
      hp: 85,
      speed: 14,
      costEmbers: 500,
    ),
    'scholar': CharacterStats(
      id: 'scholar',
      name: 'Scholar',
      hp: 95,
      speed: 11,
      costEmbers: 900,
    ),
    'brute': CharacterStats(
      id: 'brute',
      name: 'Brute',
      hp: 140,
      speed: 6,
      costEmbers: 1400,
    ),
    'ghost': CharacterStats(
      id: 'ghost',
      name: 'Ghost',
      hp: 110,
      speed: 12,
      costEmbers: 2000,
    ),
  };

  static CharacterStats? forId(String id) => byId[id];

  static int costEmbers(String id) => byId[id]?.costEmbers ?? 0;
}
