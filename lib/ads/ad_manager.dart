import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../connectivity/network_link.dart';
import '../prefs/app_flags.dart';

/// AdMob helper — UMP consent, native, App Open, interstitial, rewarded.
///
/// Call [ensureInitialized] only after agree / onboarding consent. Never from
/// [main] before the user has passed those screens.
class AdManager with WidgetsBindingObserver {
  AdManager._();
  static final AdManager instance = AdManager._();

  /// Official Google test native advanced unit.
  static const String testNativeAdUnitId =
      'ca-app-pub-3940256099942544/2247696110';

  /// Official Google test App Open unit.
  static const String testAppOpenAdUnitId =
      'ca-app-pub-3940256099942544/9257395921';

  /// Official Google test interstitial unit.
  static const String testInterstitialAdUnitId =
      'ca-app-pub-3940256099942544/1033173712';

  /// Official Google test rewarded unit.
  static const String testRewardedAdUnitId =
      'ca-app-pub-3940256099942544/5224354917';

  // Production values — safe balance: not shown on trivial quick app-switches
  // (5s minimum background), not shown too frequently to risk AdMob's
  // disruptive-ads guidance (45s cooldown). Do not lower below 5s/30s
  // without reviewing AdMob's App Open ad best practices again.
  static const _minBackground = Duration(seconds: 5);
  static const _minCooldown = Duration(seconds: 45);

  Future<void>? _initFuture;

  /// True while [GameplayHudScreen] is mounted — blocks App Open.
  bool gameplayActive = false;

  /// False on the device's first-ever session after setting [AppFlags.hasLaunchedBefore].
  bool _allowAppOpenThisSession = false;

  DateTime? _pausedAt;
  DateTime? _lastShownAt;
  AppOpenAd? _appOpenAd;
  bool _isShowingAppOpen = false;
  bool _isLoadingAppOpen = false;

  InterstitialAd? _interstitialAd;
  bool _isLoadingInterstitial = false;
  bool _isShowingInterstitial = false;

  RewardedAd? _rewardedAd;
  bool _isLoadingRewarded = false;
  bool _isShowingRewarded = false;

  bool _lifecycleAttached = false;

  /// Idempotent: UMP → Mobile Ads init → first-launch flag → preload App Open.
  /// Safe to await from Splash / native ad widgets after consent.
  Future<void> ensureInitialized() {
    return _initFuture ??= _bootstrapAds();
  }

  Future<void> _bootstrapAds() async {
    try {
      await _gatherConsent().timeout(const Duration(seconds: 8));
    } catch (e, st) {
      debugPrint('UMP consent timed out / failed: $e\n$st');
    }

    try {
      final status = await MobileAds.instance
          .initialize()
          .timeout(const Duration(seconds: 12));
      debugPrint('Mobile Ads initialized: $status');
      await MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          tagForChildDirectedTreatment:
              TagForChildDirectedTreatment.unspecified,
          tagForUnderAgeOfConsent: TagForUnderAgeOfConsent.unspecified,
        ),
      );
    } catch (e, st) {
      debugPrint('AdManager MobileAds init failed: $e\n$st');
    }

    final launchedBefore = await AppFlags.hasLaunchedBefore();
    if (!launchedBefore) {
      await AppFlags.setHasLaunchedBefore(true);
      _allowAppOpenThisSession = false;
      debugPrint('App Open: first launch — flag set, no ads this session');
    } else {
      _allowAppOpenThisSession = true;
    }

    _attachLifecycle();
    unawaited(_loadAppOpenAd());
    unawaited(loadInterstitial());
    unawaited(loadRewarded());
  }

  Future<bool> _hasNetworkForAds() async {
    final online = await NetworkLink.isOnline();
    if (!online) {
      debugPrint('AdManager: skip load — offline');
    }
    return online;
  }

  Future<void> _gatherConsent() async {
    final done = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () async {
        try {
          await ConsentForm.loadAndShowConsentFormIfRequired((_) {});
        } catch (_) {}
        if (!done.isCompleted) done.complete();
      },
      (_) {
        if (!done.isCompleted) done.complete();
      },
    );
    await done.future;
  }

  void _attachLifecycle() {
    if (_lifecycleAttached) return;
    WidgetsBinding.instance.addObserver(this);
    _lifecycleAttached = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      unawaited(_maybeShowAppOpenOnResume());
    }
  }

  Future<void> _maybeShowAppOpenOnResume() async {
    if (!_allowAppOpenThisSession) return;
    if (gameplayActive) return;
    if (_isShowingAppOpen) return;
    if (_isShowingInterstitial || _isShowingRewarded) return;

    final pausedAt = _pausedAt;
    if (pausedAt == null) return;
    final backgrounded = DateTime.now().difference(pausedAt);
    if (backgrounded < _minBackground) return;

    final last = _lastShownAt;
    if (last != null && DateTime.now().difference(last) < _minCooldown) {
      return;
    }

    await _showAppOpenAd();
  }

  Future<void> _loadAppOpenAd() async {
    if (_isLoadingAppOpen || _appOpenAd != null) return;
    if (!await _hasNetworkForAds()) return;
    _isLoadingAppOpen = true;
    try {
      await AppOpenAd.load(
        adUnitId: testAppOpenAdUnitId,
        request: const AdRequest(),
        adLoadCallback: AppOpenAdLoadCallback(
          onAdLoaded: (ad) {
            _appOpenAd = ad;
            _isLoadingAppOpen = false;
            debugPrint('App Open ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isLoadingAppOpen = false;
            _appOpenAd = null;
            debugPrint('App Open failed to load: $error');
          },
        ),
      );
    } catch (e, st) {
      _isLoadingAppOpen = false;
      debugPrint('App Open load exception: $e\n$st');
    }
  }

  Future<void> _showAppOpenAd() async {
    final ad = _appOpenAd;
    if (ad == null || _isShowingAppOpen || gameplayActive) {
      if (ad == null) unawaited(_loadAppOpenAd());
      return;
    }

    _isShowingAppOpen = true;
    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        debugPrint('App Open showed');
      },
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpen = false;
        _lastShownAt = DateTime.now();
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        );
        unawaited(restoreSystemUiAfterAd());
        unawaited(_loadAppOpenAd());
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('App Open failed to show: $error');
        ad.dispose();
        _appOpenAd = null;
        _isShowingAppOpen = false;
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
        );
        unawaited(restoreSystemUiAfterAd());
        unawaited(_loadAppOpenAd());
      },
    );

    try {
      await prepareSystemUiForAd();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
      await ad.show();
    } catch (e, st) {
      debugPrint('App Open show exception: $e\n$st');
      ad.dispose();
      _appOpenAd = null;
      _isShowingAppOpen = false;
      unawaited(restoreSystemUiAfterAd());
      unawaited(_loadAppOpenAd());
    }
  }

  Future<void> loadInterstitial() async {
    if (_isLoadingInterstitial || _interstitialAd != null) return;
    if (!await _hasNetworkForAds()) return;
    _isLoadingInterstitial = true;
    try {
      await InterstitialAd.load(
        adUnitId: testInterstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isLoadingInterstitial = false;
            debugPrint('Interstitial ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isLoadingInterstitial = false;
            _interstitialAd = null;
            debugPrint('Interstitial failed to load: $error');
          },
        ),
      );
    } catch (e, st) {
      _isLoadingInterstitial = false;
      debugPrint('Interstitial load exception: $e\n$st');
    }
  }

  /// Shows a cached interstitial if one is ready. Never blocks on a load.
  Future<void> showInterstitialIfReady() async {
    final ad = _interstitialAd;
    if (ad == null || _isShowingInterstitial) {
      if (ad == null) unawaited(loadInterstitial());
      return;
    }

    _isShowingInterstitial = true;
    _interstitialAd = null;
    final done = Completer<void>();

    void finish(InterstitialAd closing) {
      try {
        closing.dispose();
      } catch (e, st) {
        debugPrint('Interstitial dispose failed: $e\n$st');
      }
      _isShowingInterstitial = false;
      unawaited(restoreSystemUiAfterAd());
      unawaited(loadInterstitial());
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (shown) {
        debugPrint('Interstitial showed');
      },
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (failed, error) {
        debugPrint('Interstitial failed to show: $error');
        finish(failed);
      },
    );

    try {
      await prepareSystemUiForAd();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
      await ad.show();
      await done.future.timeout(const Duration(seconds: 60));
    } catch (e, st) {
      debugPrint('Interstitial show exception: $e\n$st');
      if (!done.isCompleted) finish(ad);
    }
  }

  Future<void> loadRewarded() async {
    if (_isLoadingRewarded || _rewardedAd != null) return;
    if (!await _hasNetworkForAds()) return;
    _isLoadingRewarded = true;
    try {
      await RewardedAd.load(
        adUnitId: testRewardedAdUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            _rewardedAd = ad;
            _isLoadingRewarded = false;
            debugPrint('Rewarded ad loaded');
          },
          onAdFailedToLoad: (error) {
            _isLoadingRewarded = false;
            _rewardedAd = null;
            debugPrint('Rewarded failed to load: $error');
          },
        ),
      );
    } catch (e, st) {
      _isLoadingRewarded = false;
      debugPrint('Rewarded load exception: $e\n$st');
    }
  }

  /// Shows a cached rewarded ad if ready. Returns false immediately when none.
  Future<bool> showRewardedIfReady({
    required void Function() onUserEarnedReward,
  }) async {
    final ad = _rewardedAd;
    if (ad == null || _isShowingRewarded) {
      if (ad == null) unawaited(loadRewarded());
      return false;
    }

    _isShowingRewarded = true;
    _rewardedAd = null;
    final done = Completer<void>();

    void finish(RewardedAd closing) {
      try {
        closing.dispose();
      } catch (e, st) {
        debugPrint('Rewarded dispose failed: $e\n$st');
      }
      _isShowingRewarded = false;
      unawaited(restoreSystemUiAfterAd());
      unawaited(loadRewarded());
      if (!done.isCompleted) done.complete();
    }

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (shown) {
        debugPrint('Rewarded showed');
      },
      onAdDismissedFullScreenContent: finish,
      onAdFailedToShowFullScreenContent: (failed, error) {
        debugPrint('Rewarded failed to show: $error');
        finish(failed);
      },
    );

    try {
      await prepareSystemUiForAd();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.black,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
        ),
      );
      await ad.show(
        onUserEarnedReward: (rewardAd, reward) {
          debugPrint('Rewarded earned: ${reward.amount} ${reward.type}');
          onUserEarnedReward();
        },
      );
      await done.future.timeout(const Duration(seconds: 60));
      return true;
    } catch (e, st) {
      debugPrint('Rewarded show exception: $e\n$st');
      if (!done.isCompleted) finish(ad);
      return false;
    }
  }

  /// Exit immersive-sticky so AdMob's close control has system-bar space.
  Future<void> prepareSystemUiForAd() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    } catch (e, st) {
      debugPrint('AdManager prepare SystemUI failed: $e\n$st');
    }
  }

  /// Restore gameplay immersive-sticky after the ad is gone / failed.
  Future<void> restoreSystemUiAfterAd() async {
    try {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    } catch (e, st) {
      debugPrint('AdManager restore SystemUI failed: $e\n$st');
    }
  }
}
