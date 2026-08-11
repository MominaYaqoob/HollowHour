import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'game_mode.dart';

/// Runtime match state — HP, XP, timer, entities, and combat stats.
class GameState extends ChangeNotifier {
  GameState({
    this.hollowDepth = 5,
    this.playerCharacterId = 'wanderer',
    this.gameMode = GameMode.standard,
    Duration? matchDuration,
    double startingMaxHp = 100,
    double startingMoveSpeed = 175,
    double startingDamage = 12,
    double startingFireCooldown = 0.38,
    double startingProjectileSpeed = 420,
    double startingProjectileRadius = 5,
    double startingAimRangeRadius = 190,
  })  : matchDuration =
            matchDuration ?? gameMode.matchDuration,
        maxHp = startingMaxHp,
        playerHp = startingMaxHp,
        moveSpeed = startingMoveSpeed,
        projectileDamage = startingDamage,
        fireCooldownSeconds = startingFireCooldown,
        projectileSpeed = startingProjectileSpeed,
        projectileRadius = startingProjectileRadius,
        aimRangeRadius = startingAimRangeRadius,
        timeRemaining = matchDuration ?? gameMode.matchDuration;

  final int hollowDepth;
  final GameMode gameMode;
  final Duration matchDuration;

  /// Endless count-up clock (timed modes use [matchDuration] − [timeRemaining]).
  Duration _elapsedSurvival = Duration.zero;

  /// Equipped character id (wanderer/huntress/scholar/brute/ghost).
  String playerCharacterId;

  Offset playerPosition = Offset.zero;

  /// Visible viewport (screen playfield).
  Size viewSize = Size.zero;

  /// Full walkable arena — larger than [viewSize]; camera follows the player.
  Size worldSize = Size.zero;

  /// World is this many times the viewport on each axis.
  static const double worldScale = 2.4;

  /// Aim/move facing in radians (0 = right, π/2 = down). Visual only.
  double facingAngle = math.pi / 2;
  /// When true, AIM stick owns [facingAngle] over move stick.
  bool aimFacingActive = false;
  bool playerMoving = false;
  double walkAnimTime = 0;

  double playerHp;
  double maxHp;
  int level = 1;
  double xp = 0;
  double xpToNextLevel = 18;
  int killCount = 0;
  Duration timeRemaining;
  bool isPaused = false;
  bool isGameOver = false;
  bool isWin = false;

  /// True while level-up cards are showing — loop freezes.
  bool awaitingLevelUp = false;

  /// Combat modifiers (tuned by talents + weapons + runes + level-up picks).
  double moveSpeed;
  double projectileDamage;
  double fireCooldownSeconds;
  double projectileSpeed;
  double projectileRadius;
  double aimRangeRadius;

  /// Magazine — depletes on fire, reloads when empty.
  int maxAmmo = 6;
  int currentAmmo = 6;
  bool isReloading = false;
  double reloadTimer = 0;
  static const double reloadDurationSeconds = 1.2;

  /// Magnet power-up — when active, XP orbs drift from anywhere.
  bool magnetActive = false;
  double magnetTimeLeft = 0;
  double magnetSpawnTimer = 0;
  bool magnetSpawnArmed = false;

  int embersEarned = 0;
  String? lastPickupLabel;

  final List<EnemyEntity> enemies = [];
  final List<ProjectileEntity> projectiles = [];
  final List<XpOrbEntity> xpOrbs = [];
  final List<ObstacleEntity> obstacles = [];
  final List<MagnetPickupEntity> magnetPickups = [];

  bool get isRunning =>
      !isPaused && !isGameOver && !isWin && !awaitingLevelUp;

  Duration get elapsed {
    if (gameMode.isEndless) return _elapsedSurvival;
    final e = matchDuration - timeRemaining;
    return e < Duration.zero ? Duration.zero : e;
  }

  /// Survival progress level for this run (1–30), from match elapsed time.
  /// Standard/Quick: proportional to active [matchDuration].
  /// Endless: ~40s per level (Standard scale), capped at 30 for unlocks.
  int get survivalLevelReached {
    const maxLevels = 30;
    final elapsedMs = elapsed.inMilliseconds;
    if (elapsedMs <= 0) return 1;

    if (gameMode.isEndless) {
      final segmentMs =
          GameModeDuration.standardLevelInterval.inMilliseconds;
      final level = (elapsedMs / segmentMs).ceil();
      return level.clamp(1, maxLevels);
    }

    final totalMs = matchDuration.inMilliseconds;
    if (totalMs <= 0) return 1;
    final clamped = elapsedMs.clamp(0, totalMs);
    if (isWin || clamped >= totalMs) return maxLevels;
    final level = (clamped / totalMs * maxLevels).ceil();
    return level.clamp(1, maxLevels);
  }

  String get timerLabel {
    // Endless: count-up stopwatch. Timed modes: count-down.
    final t = gameMode.isEndless
        ? elapsed
        : (timeRemaining.isNegative ? Duration.zero : timeRemaining);
    final totalSec = t.inSeconds;
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get elapsedLabel {
    final t = elapsed;
    final totalSec = t.inSeconds;
    final m = (totalSec ~/ 60).toString().padLeft(2, '0');
    final s = (totalSec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// Call with the on-screen playfield size; expands [worldSize] for camera play.
  void setViewSize(Size view) {
    if (view.isEmpty || view == viewSize) return;
    final first = viewSize.isEmpty;
    viewSize = view;
    worldSize = Size(view.width * worldScale, view.height * worldScale);
    if (first) {
      playerPosition = Offset(worldSize.width / 2, worldSize.height / 2);
      _spawnObstacles(worldSize);
    }
    notifyListeners();
  }

  /// Top-left of the camera window in world space (player-centered, clamped).
  Offset get cameraTopLeft {
    if (viewSize.isEmpty || worldSize.isEmpty) return Offset.zero;
    final maxX = math.max(0.0, worldSize.width - viewSize.width);
    final maxY = math.max(0.0, worldSize.height - viewSize.height);
    return Offset(
      (playerPosition.dx - viewSize.width / 2).clamp(0.0, maxX),
      (playerPosition.dy - viewSize.height / 2).clamp(0.0, maxY),
    );
  }

  /// Places static environment props across the full world.
  void _spawnObstacles(Size size) {
    obstacles.clear();
    final rng = math.Random();
    final count = 8 + rng.nextInt(5); // 8–12 on the expanded map
    // Prefer tall gothic trees (~2.5–3× player). Rocks/bushes for variety.
    final catalog = <({String asset, double radius, double drawW, double drawH})>[
      (asset: 'assets/game/environment/tree_gothic_a.png', radius: 20, drawW: 96, drawH: 144),
      (asset: 'assets/game/environment/tree_gothic_b.png', radius: 22, drawW: 104, drawH: 152),
      (asset: 'assets/game/environment/tree_dead.png', radius: 18, drawW: 88, drawH: 132),
      (asset: 'assets/game/environment/tree_01.png', radius: 18, drawW: 88, drawH: 132),
      (asset: 'assets/game/environment/rock_01.png', radius: 16, drawW: 44, drawH: 44),
      (asset: 'assets/game/environment/rock_02.png', radius: 16, drawW: 44, drawH: 44),
      (asset: 'assets/game/environment/bush_dead.png', radius: 14, drawW: 48, drawH: 48),
      (asset: 'assets/game/environment/bush_autumn.png', radius: 14, drawW: 48, drawH: 48),
    ];
    // Bias spawn rolls toward gothic trees.
    final weighted = <({String asset, double radius, double drawW, double drawH})>[
      ...List.filled(3, catalog[0]),
      ...List.filled(3, catalog[1]),
      ...catalog.skip(2),
    ];

    final center = Offset(size.width / 2, size.height / 2);
    var attempts = 0;
    while (obstacles.length < count && attempts < 80) {
      attempts++;
      final entry = weighted[rng.nextInt(weighted.length)];
      final pos = Offset(
        40 + rng.nextDouble() * (size.width - 80),
        40 + rng.nextDouble() * (size.height - 80),
      );
      // Keep clear of spawn center and other obstacle bases.
      if ((pos - center).distance < 90) continue;
      var overlaps = false;
      for (final o in obstacles) {
        if ((pos - o.position).distance < o.radius + entry.radius + 28) {
          overlaps = true;
          break;
        }
      }
      if (overlaps) continue;
      obstacles.add(
        ObstacleEntity(
          position: pos,
          radius: entry.radius,
          assetPath: entry.asset,
          drawWidth: entry.drawW,
          drawHeight: entry.drawH,
        ),
      );
    }
  }

  /// Push [position] outside overlapping obstacle circles (projectiles ignore).
  static Offset resolveObstacleCollision(
    Offset position,
    double radius,
    List<ObstacleEntity> obstacles,
  ) {
    var p = position;
    for (final o in obstacles) {
      final delta = p - o.position;
      final minDist = radius + o.radius;
      final distSq = delta.distanceSquared;
      if (distSq >= minDist * minDist) continue;
      if (distSq < 0.0001) {
        p = o.position + Offset(minDist, 0);
        continue;
      }
      final dist = math.sqrt(distSq);
      p = o.position + delta * (minDist / dist);
    }
    return p;
  }

  void setPaused(bool value) {
    if (isPaused == value) return;
    isPaused = value;
    notifyListeners();
  }

  void takeDamage(double amount) {
    if (amount <= 0 || isGameOver || isWin) return;
    playerHp = (playerHp - amount).clamp(0, maxHp);
    if (playerHp <= 0) {
      playerHp = 0;
      isGameOver = true;
    }
    notifyListeners();
  }

  void addXp(double amount) {
    if (amount <= 0 || isGameOver || isWin) return;
    xp += amount;
    while (xp >= xpToNextLevel && !isGameOver && !isWin) {
      xp -= xpToNextLevel;
      level += 1;
      xpToNextLevel = (xpToNextLevel * 1.35 + 6).roundToDouble();
      awaitingLevelUp = true;
      isPaused = true;
      break; // one choice at a time
    }
    notifyListeners();
  }

  void tick(Duration delta) {
    if (!isRunning) return;
    if (gameMode.isEndless) {
      // Count up forever — death is the only end condition.
      _elapsedSurvival += delta;
      notifyListeners();
      return;
    }
    timeRemaining -= delta;
    if (timeRemaining <= Duration.zero) {
      timeRemaining = Duration.zero;
      if (playerHp > 0) {
        isWin = true;
      } else {
        isGameOver = true;
      }
    }
    notifyListeners();
  }

  void completeLevelUp() {
    awaitingLevelUp = false;
    isPaused = false;
    notifyListeners();
  }

  void notePickup(String label) {
    lastPickupLabel = label;
    notifyListeners();
  }

  void addEmbersEarned(int amount) {
    if (amount <= 0) return;
    embersEarned += amount;
  }

  /// Frame refresh for entity paints when no GameState field setter ran.
  void markDirty() => notifyListeners();
}

/// Lightweight enemy record owned by [GameState].
class EnemyEntity {
  EnemyEntity({
    required this.position,
    required this.hp,
    required this.maxHp,
    required this.speed,
    required this.damage,
    required this.radius,
    required this.type,
  });

  Offset position;
  double hp;
  final double maxHp;
  final double speed;
  final double damage;
  final double radius;
  final EnemyKind type;

  /// Visual-only walk cycle clock (seconds).
  double walkAnimTime = 0;

  /// Visual-only: true when facing left (flip sprite).
  bool facingLeft = false;

  /// Visual-only: true while actively chasing this frame.
  bool moving = false;

  bool get isDead => hp <= 0;
}

enum EnemyKind { fast, tank, ranged }

class ProjectileEntity {
  ProjectileEntity({
    required this.position,
    required this.direction,
    required this.speed,
    required this.damage,
    this.radius = 5,
  });

  Offset position;
  Offset direction;
  final double speed;
  final double damage;
  final double radius;
}

class XpOrbEntity {
  XpOrbEntity({
    required this.position,
    required this.amount,
    this.radius = 8,
  });

  Offset position;
  final double amount;
  final double radius;
}

/// Static environment blocker — circular base collision only.
class ObstacleEntity {
  ObstacleEntity({
    required this.position,
    required this.radius,
    required this.assetPath,
    required this.drawWidth,
    required this.drawHeight,
  });

  final Offset position;
  final double radius;
  final String assetPath;
  final double drawWidth;
  final double drawHeight;
}

class MagnetPickupEntity {
  MagnetPickupEntity({
    required this.position,
    this.radius = 14,
  });

  Offset position;
  final double radius;
}
