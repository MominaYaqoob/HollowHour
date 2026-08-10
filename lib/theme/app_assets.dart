/// Central asset paths for Hollow Hour art.
class AppAssets {
  AppAssets._();

  static const brandingIcon = 'assets/branding/hollow_hour_app_icon.png';
  static const brandingLogo = 'assets/branding/hollow_hour_logo_horizontal.png';

  static const bgField = 'assets/bg/bg_hollow_field.png';
  static const bgFog = 'assets/bg/bg_fog_layer.png';

  static const iconEmbers = 'assets/icons/icon_embers.png';
  static const iconLock = 'assets/icons/icon_lock.png';
  static const iconHp = 'assets/icons/icon_hp.png';
  static const iconSettings = 'assets/icons/icon_settings.png';
  static const iconShop = 'assets/icons/icon_shop.png';
  static const iconPause = 'assets/icons/icon_pause.png';

  static const charWanderer = 'assets/characters/char_wanderer.png';
  static const charWandererLocked = 'assets/characters/char_wanderer_locked.png';
  static const charHuntress = 'assets/characters/char_huntress.png';
  static const charHuntressLocked = 'assets/characters/char_huntress_locked.png';
  static const charScholar = 'assets/characters/char_scholar.png';
  static const charScholarLocked = 'assets/characters/char_scholar_locked.png';
  static const charBrute = 'assets/characters/char_brute.png';
  static const charBruteLocked = 'assets/characters/char_brute_locked.png';
  static const charGhost = 'assets/characters/char_ghost.png';
  static const charGhostLocked = 'assets/characters/char_ghost_locked.png';

  /// Top-down gameplay sprites (same character ids as select/shop/prepare).
  static const gamePlayerIds = [
    'wanderer',
    'huntress',
    'scholar',
    'brute',
    'ghost',
  ];

  static String gamePlayerIdle(String characterId, {String facing = 'down'}) {
    final id = gamePlayerIds.contains(characterId) ? characterId : 'wanderer';
    return switch (facing) {
      'up' => 'assets/game/player/${id}_idle_up.png',
      'side' => 'assets/game/player/${id}_idle_side.png',
      _ => 'assets/game/player/${id}_idle.png',
    };
  }

  static String gamePlayerWalk(String characterId, {String facing = 'down'}) {
    final id = gamePlayerIds.contains(characterId) ? characterId : 'wanderer';
    return switch (facing) {
      'up' => 'assets/game/player/${id}_walk_up.png',
      'side' => 'assets/game/player/${id}_walk_side.png',
      _ => 'assets/game/player/${id}_walk.png',
    };
  }

  /// Portrait used in Character Select / Shop / Prepare for [characterId].
  static String characterPortrait(String characterId) {
    return switch (characterId) {
      'huntress' => charHuntress,
      'scholar' => charScholar,
      'brute' => charBrute,
      'ghost' => charGhost,
      _ => charWanderer,
    };
  }

  static const gameEnemyKinds = ['fast', 'tank', 'ranged'];

  static String gameEnemyIdle(String kind) =>
      'assets/game/enemies/$kind/idle.png';

  static String gameEnemyWalk(String kind) =>
      'assets/game/enemies/$kind/walk.png';

  static const gameXpOrb = 'assets/game/pickups/xp_orb.png';
  static const gameMagnet = 'assets/game/pickups/magnet.png';

  static const gameEnvTree01 = 'assets/game/environment/tree_01.png';
  static const gameEnvTreeDead = 'assets/game/environment/tree_dead.png';
  static const gameEnvTreeGothicA = 'assets/game/environment/tree_gothic_a.png';
  static const gameEnvTreeGothicB = 'assets/game/environment/tree_gothic_b.png';
  static const gameEnvRock01 = 'assets/game/environment/rock_01.png';
  static const gameEnvRock02 = 'assets/game/environment/rock_02.png';
  static const gameEnvBushDead = 'assets/game/environment/bush_dead.png';
  static const gameEnvBushAutumn = 'assets/game/environment/bush_autumn.png';

  static const gameObstacleAssets = [
    gameEnvTreeGothicA,
    gameEnvTreeGothicB,
    gameEnvTree01,
    gameEnvTreeDead,
    gameEnvRock01,
    gameEnvRock02,
    gameEnvBushDead,
    gameEnvBushAutumn,
  ];
}
