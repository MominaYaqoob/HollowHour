import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../prefs/app_flags.dart';

/// AdMob helper — UMP consent, native ads, App Open, System-UI helpers.
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

  static const _minBackground = Duration(seconds: 5);
  static const _minCooldown = Duration(minutes: 3);

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
