import 'dart:async';

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

  static const int _sfxPoolSize = 4;

  AudioPlayer? _music;
  final List<AudioPlayer> _sfxPool = [];
  int _sfxCursor = 0;
  bool _initialized = false;
  bool _musicStarted = false;
  bool _musicPausedByApp = false;
  Future<void>? _playMusicChain;

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

    // Music player — keep setup minimal so Android devices don't reject it.
    try {
      _music = AudioPlayer();
      await _music!.setPlayerMode(PlayerMode.mediaPlayer);
      await _music!.setReleaseMode(ReleaseMode.loop);
      await _music!.setVolume(0.55);
    } catch (e, st) {
      debugPrint('AudioManager.init music failed: $e\n$st');
      _music = null;
    }

    // SFX pool separate — never wipe music if this fails.
    try {
      await _ensureSfxPool();
    } catch (e, st) {
      debugPrint('AudioManager.init sfx pool failed: $e\n$st');
    }

    _initialized = true;
  }

  Future<void> _ensureSfxPool() async {
    if (_sfxPool.isNotEmpty) return;
    for (var i = 0; i < _sfxPoolSize; i++) {
      try {
        final p = AudioPlayer();
        await p.setPlayerMode(PlayerMode.lowLatency);
        await p.setReleaseMode(ReleaseMode.release);
        await p.setVolume(0.85);
        // Avoid stealing Android audio focus from looping music.
        try {
          await p.setAudioContext(
            AudioContext(
              android: const AudioContextAndroid(
                contentType: AndroidContentType.sonification,
                usageType: AndroidUsageType.game,
                audioFocus: AndroidAudioFocus.none,
              ),
            ),
          );
        } catch (_) {}
        _sfxPool.add(p);
      } catch (e) {
        debugPrint('AudioManager SFX pool slot failed: $e');
      }
    }
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
      _musicPausedByApp = false;
      await playMusic(forceRestart: true);
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

  Future<AudioPlayer> _obtainMusicPlayer() async {
    if (!_initialized) await init();
    if (_music != null) return _music!;
    final player = AudioPlayer();
    await player.setPlayerMode(PlayerMode.mediaPlayer);
    await player.setReleaseMode(ReleaseMode.loop);
    await player.setVolume(0.55);
    _music = player;
    return player;
  }

  /// Start (or resume) looping music if Background Sound is on.
  Future<void> playMusic({bool forceRestart = false}) {
    final previous = _playMusicChain ?? Future<void>.value();
    final next = previous.catchError((_) {}).then((_) async {
      await _playMusicImpl(forceRestart: forceRestart);
    });
    _playMusicChain = next;
    return next;
  }

  Future<void> _playMusicImpl({required bool forceRestart}) async {
    if (!_initialized) await init();
    if (!musicEnabled) return;
    _musicPausedByApp = false;

    try {
      var player = await _obtainMusicPlayer();

      if (!forceRestart) {
        if (player.state == PlayerState.playing) return;
        if (player.state == PlayerState.paused && _musicStarted) {
          await player.resume();
          return;
        }
      }

      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.55);
      await player.stop();
      await player.play(AssetSource(_musicAsset));
      _musicStarted = true;
      debugPrint('AudioManager: music playing');
    } catch (e, st) {
      debugPrint('AudioManager.playMusic failed: $e\n$st');
      _musicStarted = false;
      // Recreate player once and retry — recovers from native focus/player death.
      try {
        await _music?.dispose();
      } catch (_) {}
      _music = null;
      try {
        final player = await _obtainMusicPlayer();
        await player.setReleaseMode(ReleaseMode.loop);
        await player.play(AssetSource(_musicAsset));
        _musicStarted = true;
        debugPrint('AudioManager: music playing after recreate');
      } catch (e2, st2) {
        debugPrint('AudioManager.playMusic retry failed: $e2\n$st2');
      }
    }
  }

  /// Temporary pause (e.g. Pause overlay). Does not clear the Music switch.
  Future<void> pauseMusic() async {
    final player = _music;
    if (player == null) return;
    try {
      if (player.state == PlayerState.playing) {
        _musicPausedByApp = true;
        await player.pause();
      }
    } catch (e) {
      debugPrint('AudioManager.pauseMusic failed: $e');
    }
  }

  Future<void> resumeMusic() async {
    if (!musicEnabled) return;
    _musicPausedByApp = false;
    final player = _music;
    if (player == null) {
      await playMusic();
      return;
    }
    try {
      if (player.state == PlayerState.paused) {
        await player.resume();
        return;
      }
      if (player.state != PlayerState.playing) {
        await playMusic();
      }
    } catch (e) {
      debugPrint('AudioManager.resumeMusic failed: $e');
      await playMusic(forceRestart: true);
    }
  }

  /// Call after fullscreen ads / focus loss so music keeps going.
  Future<void> ensureMusicPlaying() async {
    if (!musicEnabled || _musicPausedByApp) return;
    final player = _music;
    if (player == null || player.state != PlayerState.playing) {
      await playMusic();
    }
  }

  Future<void> stopMusic() async {
    final player = _music;
    if (player == null) return;
    try {
      _musicPausedByApp = true;
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
      await _ensureSfxPool();
      if (_sfxPool.isEmpty) return;
      final player = _sfxPool[_sfxCursor % _sfxPool.length];
      _sfxCursor++;
      await player.stop();
      await player.play(AssetSource(asset));
    } catch (e) {
      debugPrint('AudioManager SFX "$asset" failed: $e');
    }
  }
}
