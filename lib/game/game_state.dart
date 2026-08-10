import 'package:flutter/material.dart';

/// Runtime match state — HP, XP, timer, entities, and combat stats.
class GameState extends ChangeNotifier {
  GameState({
    this.hollowDepth = 5,
    Duration matchDuration = const Duration(minutes: 20),
    double startingMaxHp = 100,
    double startingMoveSpeed = 175,
    double startingDamage = 12,
    double startingFireCooldown = 0.38,
  })  : maxHp = startingMaxHp,
        playerHp = startingMaxHp,
        moveSpeed = startingMoveSpeed,
        projectileDamage = startingDamage,
        fireCooldownSeconds = startingFireCooldown,
        timeRemaining = matchDuration,
        matchDuration = matchDuration;

  final int hollowDepth;
  final Duration matchDuration;

  Offset playerPosition = Offset.zero;
  Size worldSize = Size.zero;

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

  /// Combat modifiers (tuned by talents + level-up picks).
  double moveSpeed;
  double projectileDamage;
  double fireCooldownSeconds;

  int embersEarned = 0;
  String? lastPickupLabel;

  final List<EnemyEntity> enemies = [];
  final List<ProjectileEntity> projectiles = [];
  final List<XpOrbEntity> xpOrbs = [];

  bool get isRunning =>
      !isPaused && !isGameOver && !isWin && !awaitingLevelUp;

  Duration get elapsed =>
      matchDuration - timeRemaining < Duration.zero
          ? Duration.zero
          : matchDuration - timeRemaining;

  String get timerLabel {
    final t = timeRemaining.isNegative ? Duration.zero : timeRemaining;
    final m = t.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = t.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String get elapsedLabel {
    final t = elapsed;
    final m = t.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = t.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void setWorldSize(Size size) {
    if (size == worldSize || size.isEmpty) return;
    final first = worldSize.isEmpty;
    worldSize = size;
    if (first) {
      playerPosition = Offset(size.width / 2, size.height / 2);
    }
    notifyListeners();
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
