import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/game/hp_segments.dart';

void main() {
  test('hpDamagedIndex matches HUD pip math', () {
    expect(
      hpDamagedIndex(playerHp: 0, maxHp: 100),
      -1,
    );
    expect(
      hpDamagedIndex(playerHp: 100, maxHp: 100),
      2,
    );
    expect(
      hpDamagedIndex(playerHp: 50, maxHp: 100),
      1,
    );
  });

  test('isHpCritical when last of 3 segments remains', () {
    expect(isHpCritical(playerHp: 100, maxHp: 100), isFalse);
    expect(isHpCritical(playerHp: 50, maxHp: 100), isFalse);
    expect(isHpCritical(playerHp: 100 * 1 / 3, maxHp: 100), isTrue);
    expect(isHpCritical(playerHp: 10, maxHp: 100), isTrue);
    expect(isHpCritical(playerHp: 0, maxHp: 100), isFalse);
  });
}
