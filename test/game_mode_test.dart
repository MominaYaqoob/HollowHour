import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/game_mode.dart';
import 'package:hollow_hour/game/game_state.dart';

void main() {
  test('stage duration scales from ~1m at Lv1 to 15m at Lv30', () {
    expect(stageDurationForLevel(1), const Duration(minutes: 1));
    expect(stageDurationForLevel(30), const Duration(minutes: 15));
    expect(
      stageDurationForLevel(15).inMilliseconds,
      greaterThan(stageDurationForLevel(1).inMilliseconds),
    );
    expect(
      stageDurationForLevel(15).inMilliseconds,
      lessThan(stageDurationForLevel(30).inMilliseconds),
    );
  });

  test('stage depth maps 1–30 into 1–15', () {
    expect(stageDepthForLevel(1), 1);
    expect(stageDepthForLevel(30), 15);
    expect(stageDepthForLevel(15), inInclusiveRange(1, 15));
  });

  test('stage match wins when countdown completes', () {
    final state = GameState(
      gameMode: GameMode.standard,
      matchDuration: stageDurationForLevel(1),
      hollowDepth: stageDepthForLevel(1),
    );
    expect(state.timerLabel, '01:00');
    state.tick(const Duration(seconds: 59));
    expect(state.isWin, isFalse);
    state.tick(const Duration(seconds: 1));
    expect(state.isWin, isTrue);
    expect(state.timerLabel, '00:00');
  });
}
