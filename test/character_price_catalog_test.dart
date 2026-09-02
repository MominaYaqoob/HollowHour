import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/character_catalog.dart';
import 'package:hollow_hour/screens/character_select_screen.dart';
import 'package:hollow_hour/theme/app_assets.dart';

void main() {
  test('character unlock prices match Huntress 500 through Ghost 2000', () {
    expect(CharacterCatalog.costEmbers('wanderer'), 0);
    expect(CharacterCatalog.costEmbers('huntress'), 500);
    expect(CharacterCatalog.costEmbers('scholar'), 900);
    expect(CharacterCatalog.costEmbers('brute'), 1400);
    expect(CharacterCatalog.costEmbers('ghost'), 2000);
  });

  test('character select unlockCost reads the same catalog', () {
    const ghost = GameCharacter(
      id: 'ghost',
      name: 'Ghost',
      abilityIcon: Icons.flash_on_outlined,
      abilityName: 'Rift Slash',
      portraitAsset: AppAssets.charGhost,
      lockedPortraitAsset: AppAssets.charGhostLocked,
    );
    expect(ghost.unlockCost, CharacterCatalog.costEmbers('ghost'));
    expect(ghost.unlockCost, 2000);
    expect(ghost.hp, 110);
    expect(ghost.speed, 12);
  });
}
