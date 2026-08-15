import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../audio/audio_manager.dart';

/// Google AdMob helper — TEST ad units only (no production IDs).
///
/// All public methods are fail-soft: load/show failures never throw to callers.
class AdManager {
  AdManager._();
  static final AdManager instance = AdManager._();

  /// Official Google test interstitial.
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Official Google test rewarded.
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  /// Failsafe so a broken full-screen ad never leaves a black screen forever.
  static const Duration _showTimeout = Duration(seconds: 12);
  static const Duration _loadWait = Duration(seconds: 8);

  /// Dismiss failsafe if close/dismiss never fires (close-button visibility bug).
  static const Duration _dismissFailsafe = Duration(seconds: 25);

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;
  bool _initialized = false;
  Completer<void>? _interstitialLoadGate;
  Completer<void>? _rewardedLoadGate;
  bool _interstitialShowing = false;
  bool _rewardedShowing = false;

  bool get isRewardedReady => _rewardedAd != null;
  bool get isInterstitialReady => _interstitialAd != null;

  /// Exit immersive-sticky so AdMob's close control has system-bar space.
  Future<void> _prepareSystemUiForAd() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (e, st) {
      debugPrint('AdManager prepare SystemUI failed: $e\n$st');
    }
  }

  /// Restore gameplay immersive-sticky after the ad is gone / failed.
  Future<void> _restoreSystemUiAfterAd() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e, st) {
      debugPrint('AdManager restore SystemUI failed: $e\n$st');
    }
  }

  /// Call once at app startup after [MobileAds.instance.initialize].
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Brief settle time — some devices reject loads fired instantly after init.
      await Future<void>.delayed(const Duration(milliseconds: 400));
      await Future.wait<void>([
        preloadInterstitial(),
        preloadRewarded(),
      ]);
      debugPrint(
        'AdManager ready — interstitial=$isInterstitialReady '
        'rewarded=$isRewardedReady',
      );
    } catch (e, st) {
      debugPrint('AdManager init failed: $e\n$st');
    }
  }

  Future<void> preloadInterstitial() async {
    if (_interstitialAd != null || _interstitialShowing) return;
    if (_interstitialLoading) {
      await _interstitialLoadGate?.future;
      return;
    }

    _interstitialLoading = true;
    final gate = Completer<void>();
    _interstitialLoadGate = gate;

    try {
      await InterstitialAd.load(
        adUnitId: testInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Interstitial loaded');
            _interstitialAd = ad;
            _interstitialLoading = false;
            if (!gate.isCompleted) gate.complete();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial failed to load: $error');
            _interstitialAd = null;
            _interstitialLoading = false;
            if (!gate.isCompleted) gate.complete();
            // Retry later — first attempt often fails on cold start.
            Future<void>.delayed(const Duration(seconds: 8), () {
              unawaited(preloadInterstitial());
            });
          },
        ),
      );
      await gate.future.timeout(
        _loadWait,
        onTimeout: () {
          debugPrint('Interstitial load timed out waiting for callback');
          _interstitialLoading = false;
          if (!gate.isCompleted) gate.complete();
        },
      );
    } catch (e, st) {
      debugPrint('Interstitial load exception: $e\n$st');
      _interstitialAd = null;
      _interstitialLoading = false;
      if (!gate.isCompleted) gate.complete();
    }
  }

  Future<void> preloadRewarded() async {
    if (_rewardedAd != null || _rewardedShowing) return;
    if (_rewardedLoading) {
      await _rewardedLoadGate?.future;
      return;
    }

    _rewardedLoading = true;
    final gate = Completer<void>();
    _rewardedLoadGate = gate;

    try {
      await RewardedAd.load(
        adUnitId: testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            debugPrint('Rewarded loaded');
            _rewardedAd = ad;
            _rewardedLoading = false;
            if (!gate.isCompleted) gate.complete();
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded failed to load: $error');
            _rewardedAd = null;
            _rewardedLoading = false;
            if (!gate.isCompleted) gate.complete();
            Future<void>.delayed(const Duration(seconds: 8), () {
              unawaited(preloadRewarded());
            });
          },
        ),
      );
      await gate.future.timeout(
        _loadWait,
        onTimeout: () {
          debugPrint('Rewarded load timed out waiting for callback');
          _rewardedLoading = false;
          if (!gate.isCompleted) gate.complete();
        },
      );
    } catch (e, st) {
      debugPrint('Rewarded load exception: $e\n$st');
      _rewardedAd = null;
      _rewardedLoading = false;
      if (!gate.isCompleted) gate.complete();
    }
  }

  void _safeDispose(Ad ad) {
    try {
      ad.dispose();
    } catch (e, st) {
      debugPrint('Ad dispose exception: $e\n$st');
    }
  }

  /// Shows a test interstitial if ready; waits briefly for a load first.
  ///
  /// [onPresented] fires when the full-screen ad is actually visible (or when
  /// the attempt is skipped/failed) so UI can clear loading overlays.
  Future<void> showInterstitial({VoidCallback? onPresented}) async {
    if (_interstitialShowing) {
      onPresented?.call();
      return;
    }

    final completer = Completer<void>();
    var finished = false;
    var presentedNotified = false;
    var didShow = false;

    void notifyPresented() {
      if (presentedNotified) return;
      presentedNotified = true;
      onPresented?.call();
    }

    void finish() {
      if (finished) return;
      finished = true;
      _interstitialShowing = false;
      notifyPresented();
      unawaited(AudioManager.instance.ensureMusicPlaying());
      if (!completer.isCompleted) completer.complete();
    }

    try {
      if (_interstitialAd == null) {
        debugPrint('Interstitial not ready — waiting for load…');
        await preloadInterstitial();
      }

      final ad = _interstitialAd;
      if (ad == null) {
        debugPrint('Interstitial still null — skipping show');
        unawaited(preloadInterstitial());
        finish();
        return completer.future;
      }

      _interstitialAd = null;
      _interstitialShowing = true;
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial showed');
          didShow = true;
          notifyPresented();
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Interstitial dismissed');
          unawaited(_restoreSystemUiAfterAd());
          _safeDispose(ad);
          unawaited(preloadInterstitial());
          finish();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial failed to show: $error');
          unawaited(_restoreSystemUiAfterAd());
          _safeDispose(ad);
          unawaited(preloadInterstitial());
          finish();
        },
      );
      // Leave app immersive-sticky so the ad close control can render.
      await _prepareSystemUiForAd();
      // Google's documented workaround: disable the ad's own immersive mode.
      await ad.setImmersiveMode(false);
      await ad.show();
    } catch (e, st) {
      debugPrint('Interstitial show exception: $e\n$st');
      unawaited(_restoreSystemUiAfterAd());
      unawaited(preloadInterstitial());
      finish();
    }

    // If it never appeared, skip quickly. Once shown, wait for real dismiss
    // (forced finish under a live ad caused blank/X-only chrome at level end).
    unawaited(Future<void>.delayed(_showTimeout, () {
      if (!finished && !didShow) {
        debugPrint('Interstitial never showed — skipping');
        unawaited(_restoreSystemUiAfterAd());
        finish();
      }
    }));
    unawaited(Future<void>.delayed(_dismissFailsafe, () {
      if (!finished) {
        debugPrint('Interstitial dismiss failsafe — forcing close');
        unawaited(_restoreSystemUiAfterAd());
        finish();
      }
    }));
    return completer.future;
  }

  /// Shows a test rewarded ad. Returns `true` only if the user earned the reward.
  Future<bool> showRewarded({VoidCallback? onPresented}) async {
    if (_rewardedShowing) {
      onPresented?.call();
      return false;
    }

    final completer = Completer<bool>();
    var finished = false;
    var earned = false;
    var presentedNotified = false;
    var didShow = false;

    void notifyPresented() {
      if (presentedNotified) return;
      presentedNotified = true;
      onPresented?.call();
    }

    void finish(bool result) {
      if (finished) return;
      finished = true;
      _rewardedShowing = false;
      notifyPresented();
      unawaited(AudioManager.instance.ensureMusicPlaying());
      if (!completer.isCompleted) completer.complete(result);
    }

    try {
      if (_rewardedAd == null) {
        debugPrint('Rewarded not ready — waiting for load…');
        await preloadRewarded();
      }

      final ad = _rewardedAd;
      if (ad == null) {
        debugPrint('Rewarded still null — skipping show');
        unawaited(preloadRewarded());
        finish(false);
        return completer.future;
      }

      _rewardedAd = null;
      _rewardedShowing = true;

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded showed');
          didShow = true;
          notifyPresented();
        },
        onAdDismissedFullScreenContent: (ad) {
          debugPrint('Rewarded dismissed');
          unawaited(_restoreSystemUiAfterAd());
          _safeDispose(ad);
          unawaited(preloadRewarded());
          finish(earned);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded failed to show: $error');
          unawaited(_restoreSystemUiAfterAd());
          _safeDispose(ad);
          unawaited(preloadRewarded());
          finish(false);
        },
      );

      // Leave app immersive-sticky so the ad close control can render.
      await _prepareSystemUiForAd();
      // Google's documented workaround: disable the ad's own immersive mode.
      await ad.setImmersiveMode(false);
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (e, st) {
      debugPrint('Rewarded show exception: $e\n$st');
      unawaited(_restoreSystemUiAfterAd());
      unawaited(preloadRewarded());
      finish(false);
    }

    unawaited(Future<void>.delayed(_showTimeout, () {
      if (!finished && !didShow) {
        debugPrint('Rewarded never showed — skipping');
        unawaited(_restoreSystemUiAfterAd());
        finish(earned);
      }
    }));
    unawaited(Future<void>.delayed(_dismissFailsafe, () {
      if (!finished) {
        debugPrint('Rewarded dismiss failsafe — forcing close');
        unawaited(_restoreSystemUiAfterAd());
        finish(earned);
      }
    }));
    return completer.future;
  }
}
