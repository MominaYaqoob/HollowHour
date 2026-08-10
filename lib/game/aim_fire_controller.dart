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

  bool get isAiming => _dragging && aim != Offset.zero;

  void onPanStart(Offset localDelta, double outerRadius) {
    _dragging = true;
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
  }

  void _fire() {
    final dir = aim;
    if (dir == Offset.zero) return;
    state.projectiles.add(
      ProjectileEntity(
        position: state.playerPosition,
        direction: dir,
        speed: 420,
        damage: state.projectileDamage,
      ),
    );
    _cooldownLeft = state.fireCooldownSeconds;
    AudioManager.instance.playFire();
  }

  void update(Duration delta) {
    final dt = delta.inMicroseconds / 1e6;
    if (dt <= 0) return;

    if (_cooldownLeft > 0) {
      _cooldownLeft = math.max(0, _cooldownLeft - dt);
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
