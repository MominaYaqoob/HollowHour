import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// App-wide music + SFX + haptics. Missing/corrupt assets fail silently.
class AudioManager {
  AudioManager._();
  static final AudioManager instance = AudioManager._();

  static const _musicKey = 'audio_music_enabled';
  static const _sfxKey = 'audio_sfx_enabled';
  static const _vibrationKey = 'audio_vibration_enabled';

  static const _musicAsset = 'audio/music_ambient.mp3';
  static const _fire = 'audio/sfx_fire.mp3';
  static const _hit = 'audio/sfx_hit.mp3';
  static const _enemyDeath = 'audio/sfx_enemy_death.mp3';
  static const _damage = 'audio/sfx_damage.mp3';
  static const _pickup = 'audio/sfx_pickup.mp3';
  static const _levelUp = 'audio/sfx_levelup.mp3';
  static const _tap = 'audio/sfx_tap.mp3';
  static const _purchase = 'audio/sfx_purchase.mp3';

  AudioPlayer? _music;
  bool _initialized = false;
  bool _musicStarted = false;

  bool musicEnabled = true;
  bool sfxEnabled = true;
  bool vibrationEnabled = true;

  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      musicEnabled = prefs.getBool(_musicKey) ?? true;
      sfxEnabled = prefs.getBool(_sfxKey) ?? true;
      vibrationEnabled = prefs.getBool(_vibrationKey) ?? true;
    } catch (e) {
      debugPrint('AudioManager.init prefs failed: $e');
    }
    try {
      _music ??= AudioPlayer(playerId: 'hh_music');
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.42);
    } catch (e, st) {
      debugPrint('AudioManager.init player failed: $e\n$st');
      _music = null;
    }
    _initialized = true;
  }

  Future<void> setMusicEnabled(bool enabled) async {
    musicEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_musicKey, enabled);
    } catch (e) {
      debugPrint('AudioManager.setMusicEnabled prefs failed: $e');
    }
    if (!enabled) {
      await stopMusic();
    } else {
      await playMusic();
    }
  }

  Future<void> setSfxEnabled(bool enabled) async {
    sfxEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_sfxKey, enabled);
    } catch (e) {
      debugPrint('AudioManager.setSfxEnabled prefs failed: $e');
    }
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    vibrationEnabled = enabled;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_vibrationKey, enabled);
    } catch (e) {
      debugPrint('AudioManager.setVibrationEnabled prefs failed: $e');
    }
  }

  Future<AudioPlayer?> _musicPlayer() async {
    if (!_initialized) await init();
    if (_music != null) return _music;
    try {
      _music = AudioPlayer(playerId: 'hh_music');
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.42);
      return _music;
    } catch (e) {
      debugPrint('AudioManager music player create failed: $e');
      _music = null;
      return null;
    }
  }

  /// Start (or resume) looping music if the user has Background Sound on.
  Future<void> playMusic() async {
    if (!_initialized) await init();
    if (!musicEnabled) return;
    final player = await _musicPlayer();
    if (player == null) return;
    try {
      final state = player.state;
      if (state == PlayerState.playing) return;
      if (state == PlayerState.paused && _musicStarted) {
        await player.resume();
        return;
      }
      await player.stop();
      await player.play(AssetSource(_musicAsset));
      _musicStarted = true;
    } catch (e) {
      debugPrint('AudioManager.playMusic failed: $e');
    }
  }

  /// Temporary pause (e.g. Pause overlay). Does not clear the Music switch.
  Future<void> pauseMusic() async {
    final player = _music;
    if (player == null) return;
    try {
      if (player.state == PlayerState.playing) {
        await player.pause();
      }
    } catch (e) {
      debugPrint('AudioManager.pauseMusic failed: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (!musicEnabled) return;
    final player = _music;
    if (player == null) {
      await playMusic();
      return;
    }
    try {
      if (player.state == PlayerState.paused) {
        await player.resume();
      } else if (!_musicStarted || player.state == PlayerState.stopped) {
        await playMusic();
      }
    } catch (e) {
      debugPrint('AudioManager.resumeMusic failed: $e');
    }
  }

  Future<void> stopMusic() async {
    final player = _music;
    if (player == null) return;
    try {
      await player.stop();
      _musicStarted = false;
    } catch (e) {
      debugPrint('AudioManager.stopMusic failed: $e');
    }
  }

  void playFire() => _playSfx(_fire);
  void playHit() => _playSfx(_hit);

  void playEnemyDeath() {
    _hapticSelection();
    _playSfx(_enemyDeath);
  }

  void playDamage() {
    _hapticMedium();
    _playSfx(_damage);
  }

  void playPickup() => _playSfx(_pickup);

  void playLevelUp() {
    _hapticLight();
    _playSfx(_levelUp);
  }

  void playTap() {
    _hapticLight();
    _playSfx(_tap);
  }

  void playPurchase() {
    _hapticSelection();
    _playSfx(_purchase);
  }

  void _hapticLight() {
    if (!vibrationEnabled) return;
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  void _hapticMedium() {
    if (!vibrationEnabled) return;
    try {
      HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  void _hapticSelection() {
    if (!vibrationEnabled) return;
    try {
      HapticFeedback.selectionClick();
    } catch (_) {}
  }

  Future<void> _playSfx(String asset) async {
    if (!_initialized) await init();
    if (!sfxEnabled) return;
    try {
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.release);
      await player.setVolume(0.85);
      await player.play(AssetSource(asset));
      player.onPlayerComplete.listen((_) {
        player.dispose();
      });
    } catch (e) {
      debugPrint('AudioManager SFX "$asset" failed: $e');
    }
  }
}
