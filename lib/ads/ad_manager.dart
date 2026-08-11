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

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _interstitialLoading = false;
  bool _rewardedLoading = false;
  bool _initialized = false;

  bool get isRewardedReady => _rewardedAd != null;

  /// Call once at app startup after [MobileAds.instance.initialize].
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      await Future.wait<void>([
        preloadInterstitial(),
        preloadRewarded(),
      ]);
    } catch (e, st) {
      debugPrint('AdManager init failed: $e\n$st');
    }
  }

  Future<void> preloadInterstitial() async {
    if (_interstitialAd != null || _interstitialLoading) return;
    _interstitialLoading = true;
    try {
      await InterstitialAd.load(
        adUnitId: testInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _interstitialLoading = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Interstitial failed to load: $error');
            _interstitialAd = null;
            _interstitialLoading = false;
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Interstitial load exception: $e\n$st');
      _interstitialAd = null;
      _interstitialLoading = false;
    }
  }

  Future<void> preloadRewarded() async {
    if (_rewardedAd != null || _rewardedLoading) return;
    _rewardedLoading = true;
    try {
      await RewardedAd.load(
        adUnitId: testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _rewardedLoading = false;
          },
          onAdFailedToLoad: (error) {
            debugPrint('Rewarded failed to load: $error');
            _rewardedAd = null;
            _rewardedLoading = false;
          },
        ),
      );
    } catch (e, st) {
      debugPrint('Rewarded load exception: $e\n$st');
      _rewardedAd = null;
      _rewardedLoading = false;
    }
  }

  void _safeDispose(Ad ad) {
    try {
      ad.dispose();
    } catch (e, st) {
      debugPrint('Ad dispose exception: $e\n$st');
    }
  }

  /// Shows a test interstitial if ready; always completes (never blocks forever).
  Future<void> showInterstitial() async {
    final completer = Completer<void>();
    var finished = false;

    void finish() {
      if (finished) return;
      finished = true;
      if (!completer.isCompleted) completer.complete();
    }

    try {
      final ad = _interstitialAd;
      if (ad == null) {
        unawaited(preloadInterstitial());
        finish();
        return completer.future;
      }

      _interstitialAd = null;
      ad.fullScreenContentCallback = FullScreenContentCallback(
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

    // Safety: never leave Retry / Main Menu hung if a callback is dropped.
    unawaited(
      Future<void>.delayed(_showTimeout, finish),
    );

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
      final ad = _rewardedAd;
      if (ad == null) {
        unawaited(preloadRewarded());
        finish(false);
        return completer.future;
      }

      _rewardedAd = null;

      ad.fullScreenContentCallback = FullScreenContentCallback(
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

    unawaited(
      Future<void>.delayed(_showTimeout, () => finish(earned)),
    );

    return completer.future;
  }
}
