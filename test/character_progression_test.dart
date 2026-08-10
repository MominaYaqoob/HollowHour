import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/game_mode.dart';
import 'package:hollow_hour/game/game_state.dart';
import 'package:hollow_hour/state/economy_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('stage unlocks: Lv1 free, clear N unlocks N+1, Lv30 unlocks next char', () {
    final economy = EconomyState();
    expect(economy.bestLevelFor('wanderer'), 0);
    expect(economy.nextPlayableLevel('wanderer'), 1);
    expect(economy.isStageUnlocked('wanderer', 1), isTrue);
    expect(economy.isStageUnlocked('wanderer', 2), isFalse);

    economy.updateCharacterLevel('wanderer', 1);
    expect(economy.bestLevelFor('wanderer'), 1);
    expect(economy.isStageUnlocked('wanderer', 2), isTrue);
    expect(economy.isStageUnlocked('wanderer', 3), isFalse);

    economy.updateCharacterLevel('wanderer', 1);
    expect(economy.bestLevelFor('wanderer'), 1);

    expect(economy.ownsCharacter('scholar'), isFalse);
    economy.updateCharacterLevel('huntress', 30);
    expect(economy.bestLevelFor('huntress'), 30);
    expect(economy.ownsCharacter('scholar'), isTrue);
  });

  test('timed stage state uses explicit matchDuration', () {
    final state = GameState(
      matchDuration: stageDurationForLevel(3),
      hollowDepth: stageDepthForLevel(3),
    );
    expect(state.matchDuration.inMinutes, greaterThanOrEqualTo(1));
    expect(state.hollowDepth, inInclusiveRange(1, 15));
  });
}
