import 'dart:math' as math;
import 'dart:ui';

import '../audio/audio_manager.dart';
import 'game_state.dart';

/// Manual aim: drag AIM stick for direction, release to fire (20MTD-style).
class AimFireController {
  AimFireController(this.state);

  final GameState state;

  /// Current aim vector (normalized), or zero when idle.
  Offset aim = Offset.zero;
  bool _dragging = false;
  double _cooldownLeft = 0;

  /// Visual-only fade for the on-player range ring (0–1).
  double rangeIndicatorAlpha = 0;

  /// Visual-only ring radius fallback when state has no aim range set.
  static const double rangeIndicatorRadius = 190;

  bool get isAiming => _dragging && aim != Offset.zero;

  void onPanStart(Offset localDelta, double outerRadius) {
    _dragging = true;
    state.aimFacingActive = true;
    _updateAim(localDelta, outerRadius);
  }

  void onPanUpdate(Offset localDelta, double outerRadius) {
    if (!_dragging) return;
    _updateAim(localDelta, outerRadius);
  }

  void onPanEnd() {
    if (_dragging && aim != Offset.zero && _cooldownLeft <= 0) {
      _fire();
    }
    _dragging = false;
    aim = Offset.zero;
    state.aimFacingActive = false;
  }

  void _beginReload() {
    if (state.isReloading) return;
    state.isReloading = true;
    state.reloadTimer = GameState.reloadDurationSeconds;
  }

  void _updateAim(Offset localDelta, double outerRadius) {
    if (outerRadius <= 0) {
      aim = Offset.zero;
      return;
    }
    final raw = Offset(
      localDelta.dx / outerRadius,
      localDelta.dy / outerRadius,
    );
    final len = raw.distance;
    if (len < 0.12) {
      aim = Offset.zero;
      return;
    }
    aim = raw / len;
    // Face toward aim while dragging (visual).
    state.facingAngle = math.atan2(aim.dy, aim.dx);
  }

  void _fire() {
    final dir = aim;
    if (dir == Offset.zero) return;
    if (state.isReloading) return;
    if (state.currentAmmo <= 0) {
      _beginReload();
      return;
    }
    state.projectiles.add(
      ProjectileEntity(
        position: state.playerPosition,
        direction: dir,
        speed: state.projectileSpeed,
        damage: state.projectileDamage,
        radius: state.projectileRadius,
      ),
    );
    state.currentAmmo -= 1;
    _cooldownLeft = state.fireCooldownSeconds;
    AudioManager.instance.playFire();
    if (state.currentAmmo <= 0) {
      _beginReload();
    }
  }

  void update(Duration delta) {
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    if (_cooldownLeft > 0) {
      _cooldownLeft = math.max(0, _cooldownLeft - dt);
    }

    if (state.isReloading) {
      state.reloadTimer -= dt;
      if (state.reloadTimer <= 0) {
        state.reloadTimer = 0;
        state.isReloading = false;
        state.currentAmmo = state.maxAmmo;
      }
    }

    // Fade range ring in while aiming, out on release/fire.
    final target = isAiming ? 1.0 : 0.0;
    final fadeSpeed = 7.0;
    if (rangeIndicatorAlpha < target) {
      rangeIndicatorAlpha =
          math.min(target, rangeIndicatorAlpha + dt * fadeSpeed);
    } else if (rangeIndicatorAlpha > target) {
      rangeIndicatorAlpha =
          math.max(target, rangeIndicatorAlpha - dt * fadeSpeed);
    }

    if (!state.isRunning) return;

    final size = state.worldSize;
    if (size.isEmpty) return;

    final remaining = <ProjectileEntity>[];
    for (final p in state.projectiles) {
      p.position += p.direction * p.speed * dt;
      final margin = 40.0;
      final onScreen = p.position.dx > -margin &&
          p.position.dy > -margin &&
          p.position.dx < size.width + margin &&
          p.position.dy < size.height + margin;
      if (onScreen) remaining.add(p);
    }
    state.projectiles
      ..clear()
      ..addAll(remaining);
  }

  Offset knuckleOffset(double maxTravel) {
    final len = aim.distance;
    if (len == 0) return Offset.zero;
    return aim * maxTravel;
  }
}
