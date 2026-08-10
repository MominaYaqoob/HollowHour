import 'game_state.dart';

/// In-run level-up upgrade ids matching the existing HUD cards.
enum LevelUpUpgrade {
  bloodbound,
  shadowStep,
  emberEdge,
}

/// Applies permanent-for-run effects when a level-up card is chosen.
class Leveling {
  Leveling._();

  static void apply(GameState state, LevelUpUpgrade upgrade) {
    switch (upgrade) {
      case LevelUpUpgrade.bloodbound:
        // +max HP and heal the same amount.
        state.maxHp += 22;
        state.playerHp = (state.playerHp + 22).clamp(0, state.maxHp);
      case LevelUpUpgrade.shadowStep:
        state.moveSpeed *= 1.12;
      case LevelUpUpgrade.emberEdge:
        state.projectileDamage *= 1.18;
        // Slightly faster fire rate (lower cooldown).
        state.fireCooldownSeconds =
            (state.fireCooldownSeconds * 0.9).clamp(0.16, 1.0);
    }
    state.completeLevelUp();
  }
}
