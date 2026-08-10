import 'dart:ui';

import '../audio/audio_manager.dart';
import 'game_state.dart';

/// Projectile/enemy/player/XP-orb overlap checks each tick.
class CollisionService {
  CollisionService(this.state);

  final GameState state;

  double _contactCooldown = 0;

  /// Seconds between contact damage ticks.
  static const contactCooldownSeconds = 0.65;

  /// Auto-collect radius around the player.
  static const xpCollectRadius = 42.0;

  void update(Duration delta, {void Function()? onPlayerDamaged}) {
    if (!state.isRunning) return;
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    if (_contactCooldown > 0) {
      _contactCooldown -= dt;
    }

    _projectilesVsEnemies();
    _enemiesVsPlayer(onPlayerDamaged);
    _collectXpOrbs();
  }

  void _projectilesVsEnemies() {
    final survivors = <ProjectileEntity>[];

    for (final p in state.projectiles) {
      var hit = false;
      for (final e in state.enemies) {
        if (e.isDead) continue;
        if (_circlesOverlap(p.position, p.radius, e.position, e.radius)) {
          e.hp -= p.damage;
          hit = true;
          if (e.isDead) {
            AudioManager.instance.playEnemyDeath();
            _onEnemyKilled(e);
          } else {
            AudioManager.instance.playHit();
          }
          break;
        }
      }
      if (!hit) survivors.add(p);
    }

    state.projectiles
      ..clear()
      ..addAll(survivors);
    state.enemies.removeWhere((e) => e.isDead);
  }

  void _onEnemyKilled(EnemyEntity e) {
    state.killCount += 1;
    final xp = switch (e.type) {
      EnemyKind.fast => 4.0,
      EnemyKind.ranged => 7.0,
      EnemyKind.tank => 12.0,
    };
    final embers = switch (e.type) {
      EnemyKind.fast => 2,
      EnemyKind.ranged => 3,
      EnemyKind.tank => 5,
    };
    state.addEmbersEarned(embers);
    state.xpOrbs.add(XpOrbEntity(position: e.position, amount: xp));
  }

  void _enemiesVsPlayer(void Function()? onPlayerDamaged) {
    if (_contactCooldown > 0) return;
    const playerRadius = 14.0;
    for (final e in state.enemies) {
      if (_circlesOverlap(
        state.playerPosition,
        playerRadius,
        e.position,
        e.radius,
      )) {
        state.takeDamage(e.damage);
        _contactCooldown = contactCooldownSeconds;
        AudioManager.instance.playDamage();
        onPlayerDamaged?.call();
        break;
      }
    }
  }

  void _collectXpOrbs() {
    if (state.xpOrbs.isEmpty) return;
    final kept = <XpOrbEntity>[];
    var gained = 0.0;
    for (final orb in state.xpOrbs) {
      final dist = (orb.position - state.playerPosition).distance;
      if (dist <= xpCollectRadius + orb.radius) {
        gained += orb.amount;
      } else {
        kept.add(orb);
      }
    }
    state.xpOrbs
      ..clear()
      ..addAll(kept);
    if (gained > 0) {
      state.addXp(gained);
      state.notePickup('+${gained.round()} XP');
      AudioManager.instance.playPickup();
    }
  }

  static bool _circlesOverlap(Offset a, double ra, Offset b, double rb) {
    final r = ra + rb;
    return (a - b).distanceSquared <= r * r;
  }
}
