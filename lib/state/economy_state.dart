import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Shared economy / progress state, persisted via SharedPreferences.
class EconomyState extends ChangeNotifier {
  EconomyState() {
    embers = 240;
    ownedCharacterIds = {'wanderer', 'huntress'};
    ownedWeaponIds = {'blade', 'pistol'};
    ownedRuneIds = {'gale'};
    equippedCharacterId = 'wanderer';
    equippedWeaponId = 'blade';
    equippedRuneIds = <String>{};
    talentLevels = {
      'maxhp': 2,
      'damage': 1,
      'speed': 0,
      'luck': 0,
      'warding': 0,
      'emberheart': 0,
    };
    characterBestLevel = {
      for (final id in characterProgressionOrder) id: 0,
    };
  }

  static const _prefsKey = 'economy_state';

  /// Wanderer → Huntress → Scholar → Brute → Ghost.
  static const characterProgressionOrder = [
    'wanderer',
    'huntress',
    'scholar',
    'brute',
    'ghost',
  ];

  static const maxCharacterLevel = 30;

  late int embers;
  late Set<String> ownedCharacterIds;
  late Set<String> ownedWeaponIds;
  late Set<String> ownedRuneIds;
  String? equippedCharacterId;
  String? equippedWeaponId;
  late Set<String> equippedRuneIds;
  late Map<String, int> talentLevels;
  late Map<String, int> characterBestLevel;

  Future<void> loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      embers = (map['embers'] as num?)?.toInt() ?? embers;
      ownedCharacterIds = _stringSet(map['ownedCharacterIds']) ?? ownedCharacterIds;
      ownedWeaponIds = _stringSet(map['ownedWeaponIds']) ?? ownedWeaponIds;
      ownedRuneIds = _stringSet(map['ownedRuneIds']) ?? ownedRuneIds;
      equippedCharacterId = map['equippedCharacterId'] as String? ?? equippedCharacterId;
      equippedWeaponId = map['equippedWeaponId'] as String? ?? equippedWeaponId;
      equippedRuneIds = _stringSet(map['equippedRuneIds']) ?? equippedRuneIds;
      final talents = map['talentLevels'];
      if (talents is Map) {
        talentLevels = {
          for (final e in talents.entries)
            e.key.toString(): (e.value as num).toInt(),
        };
      }
      final best = map['characterBestLevel'];
      if (best is Map) {
        characterBestLevel = {
          for (final id in characterProgressionOrder)
            id: (best[id] as num?)?.toInt() ?? 0,
        };
      }
      _grantProgressionUnlocks();
      notifyListeners();
    } catch (_) {
      // Keep seeded defaults if saved data is corrupt.
    }
  }

  Future<void> saveToDisk() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefsKey,
      jsonEncode({
        'embers': embers,
        'ownedCharacterIds': ownedCharacterIds.toList(),
        'ownedWeaponIds': ownedWeaponIds.toList(),
        'ownedRuneIds': ownedRuneIds.toList(),
        'equippedCharacterId': equippedCharacterId,
        'equippedWeaponId': equippedWeaponId,
        'equippedRuneIds': equippedRuneIds.toList(),
        'talentLevels': talentLevels,
        'characterBestLevel': characterBestLevel,
      }),
    );
  }

  void _persist() {
    unawaited(saveToDisk());
  }

  bool _trySpend(int amount) {
    if (amount < 0 || embers < amount) return false;
    embers -= amount;
    return true;
  }

  bool spendEmbers(int amount) {
    if (!_trySpend(amount)) return false;
    notifyListeners();
    _persist();
    return true;
  }

  void addEmbers(int amount) {
    if (amount <= 0) return;
    embers += amount;
    notifyListeners();
    _persist();
  }

  bool purchaseCharacter(String id, int cost) {
    if (ownedCharacterIds.contains(id)) return false;
    if (!_trySpend(cost)) return false;
    ownedCharacterIds.add(id);
    notifyListeners();
    _persist();
    return true;
  }

  bool purchaseWeapon(String id, int cost) {
    if (ownedWeaponIds.contains(id)) return false;
    if (!_trySpend(cost)) return false;
    ownedWeaponIds.add(id);
    notifyListeners();
    _persist();
    return true;
  }

  bool purchaseRune(String id, int cost) {
    if (ownedRuneIds.contains(id)) return false;
    if (!_trySpend(cost)) return false;
    ownedRuneIds.add(id);
    notifyListeners();
    _persist();
    return true;
  }

  void equipCharacter(String id) {
    if (!ownedCharacterIds.contains(id)) return;
    equippedCharacterId = id;
    notifyListeners();
    _persist();
  }

  void equipWeapon(String id) {
    if (!ownedWeaponIds.contains(id)) return;
    equippedWeaponId = id;
    notifyListeners();
    _persist();
  }

  void equipRune(String id) {
    if (!ownedRuneIds.contains(id)) return;
    // Match shop UI: one equipped rune at a time.
    equippedRuneIds
      ..clear()
      ..add(id);
    notifyListeners();
    _persist();
  }

  bool upgradeTalent(String id, int cost) {
    if (!_trySpend(cost)) return false;
    talentLevels[id] = (talentLevels[id] ?? 0) + 1;
    notifyListeners();
    _persist();
    return true;
  }

  int talentLevel(String id) => talentLevels[id] ?? 0;

  bool ownsCharacter(String id) => ownedCharacterIds.contains(id);
  bool ownsWeapon(String id) => ownedWeaponIds.contains(id);
  bool ownsRune(String id) => ownedRuneIds.contains(id);

  /// Highest stage level cleared for this character (0 = none yet).
  int bestLevelFor(String characterId) =>
      characterBestLevel[characterId] ?? 0;

  /// Next stage to play (1–30). Level 1 is always available when owned.
  int nextPlayableLevel(String characterId) {
    final next = bestLevelFor(characterId) + 1;
    return next.clamp(1, maxCharacterLevel);
  }

  /// Cleared levels + the immediate next stage are unlocked.
  bool isStageUnlocked(String characterId, int level) {
    if (level < 1 || level > maxCharacterLevel) return false;
    return level <= bestLevelFor(characterId) + 1;
  }

  /// Previous character in the progression sequence, or null for Wanderer.
  String? previousCharacterId(String characterId) {
    final i = characterProgressionOrder.indexOf(characterId);
    if (i <= 0) return null;
    return characterProgressionOrder[i - 1];
  }

  /// True when the prior roster character has cleared Lv 30 (free unlock path).
  bool canUnlockViaProgression(String characterId) {
    if (ownsCharacter(characterId)) return false;
    final prev = previousCharacterId(characterId);
    if (prev == null) return false;
    return bestLevelFor(prev) >= maxCharacterLevel;
  }

  /// Records a cleared stage if it beats the stored best, then saves.
  /// Call only on stage win with that stage's level number.
  void updateCharacterLevel(String characterId, int clearedLevel) {
    final clamped = clearedLevel.clamp(0, maxCharacterLevel);
    final current = bestLevelFor(characterId);
    if (clamped <= current) {
      if (_grantProgressionUnlocks()) {
        notifyListeners();
        _persist();
      }
      return;
    }
    characterBestLevel[characterId] = clamped;
    _grantProgressionUnlocks();
    notifyListeners();
    _persist();
  }

  /// Owns the next character for free when the previous hits Lv 30.
  /// Returns true if ownership changed.
  bool _grantProgressionUnlocks() {
    var changed = false;
    for (var i = 1; i < characterProgressionOrder.length; i++) {
      final prev = characterProgressionOrder[i - 1];
      final next = characterProgressionOrder[i];
      if (bestLevelFor(prev) >= maxCharacterLevel &&
          !ownedCharacterIds.contains(next)) {
        ownedCharacterIds.add(next);
        changed = true;
      }
    }
    return changed;
  }

  static Set<String>? _stringSet(dynamic value) {
    if (value is! List) return null;
    return value.map((e) => e.toString()).toSet();
  }
}
