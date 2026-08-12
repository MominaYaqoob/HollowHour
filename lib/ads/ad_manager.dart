import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

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

  static const Duration _showTimeout = Duration(seconds: 60);
  static const Duration _loadWait = Duration(seconds: 12);

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;
  bool _initialized = false;
  Completer<void>? _interstitialLoadGate;
  Completer<void>? _rewardedLoadGate;

  bool get isRewardedReady => _rewardedAd != null;
  bool get isInterstitialReady => _interstitialAd != null;

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
    if (_interstitialAd != null) return;
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
    if (_rewardedAd != null) return;
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
  Future<void> showInterstitial() async {
    final completer = Completer<void>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
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
      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Interstitial showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          _safeDispose(ad);
          unawaited(preloadInterstitial());
          finish();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Interstitial failed to show: $error');
          _safeDispose(ad);
          unawaited(preloadInterstitial());
          finish();
        },
      );
      await ad.show();
    } catch (e, st) {
      debugPrint('Interstitial show exception: $e\n$st');
      unawaited(preloadInterstitial());
      finish();
    }

    unawaited(Future<void>.delayed(_showTimeout, finish));
    return completer.future;
  }

  /// Shows a test rewarded ad. Returns `true` only if the user earned the reward.
  Future<bool> showRewarded() async {
    final completer = Completer<bool>();
    var finished = false;
    var earned = false;

    void finish(bool result) {
      if (finished) return;
      finished = true;
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

      ad.fullScreenContentCallback = FullScreenContentCallback(
        onAdShowedFullScreenContent: (ad) {
          debugPrint('Rewarded showed');
        },
        onAdDismissedFullScreenContent: (ad) {
          _safeDispose(ad);
          unawaited(preloadRewarded());
          finish(earned);
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          debugPrint('Rewarded failed to show: $error');
          _safeDispose(ad);
          unawaited(preloadRewarded());
          finish(false);
        },
      );

      await ad.show(
        onUserEarnedReward: (ad, reward) {
          earned = true;
        },
      );
    } catch (e, st) {
      debugPrint('Rewarded show exception: $e\n$st');
      unawaited(preloadRewarded());
      finish(false);
    }

    unawaited(Future<void>.delayed(_showTimeout, () => finish(earned)));
    return completer.future;
  }
}
