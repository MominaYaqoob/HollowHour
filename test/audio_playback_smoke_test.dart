import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hollow_hour/audio/audio_manager.dart';

/// Smoke-test that audio APIs don't throw (device may be silent in CI).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'audio_music_enabled': true,
      'audio_sfx_enabled': true,
    });
    await AudioManager.instance.init();
  });

  test('AudioManager plays music and SFX without throwing', () async {
    final audio = AudioManager.instance;
    await audio.playMusic();
    audio.playTap();
    audio.playPurchase();
    await audio.pauseMusic();
    await audio.resumeMusic();
    await audio.setMusicEnabled(false);
    expect(audio.musicEnabled, isFalse);
    await audio.setMusicEnabled(true);
    await audio.setSfxEnabled(false);
    audio.playTap(); // should no-op
    await audio.setSfxEnabled(true);
    await audio.stopMusic();
  });
}
