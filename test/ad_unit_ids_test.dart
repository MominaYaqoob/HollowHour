import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/ads/ad_manager.dart';

void main() {
  test('AdManager exposes official Google test units', () {
    expect(
      AdManager.testNativeAdUnitId,
      'ca-app-pub-3940256099942544/2247696110',
    );
    expect(
      AdManager.testAppOpenAdUnitId,
      'ca-app-pub-3940256099942544/9257395921',
    );
    expect(
      AdManager.testInterstitialAdUnitId,
      'ca-app-pub-3940256099942544/1033173712',
    );
    expect(
      AdManager.testRewardedAdUnitId,
      'ca-app-pub-3940256099942544/5224354917',
    );
  });

  test('AdManager exposes production units', () {
    expect(
      AdManager.prodNativeAdUnitId,
      'ca-app-pub-3463774223212169/7782638668',
    );
    expect(
      AdManager.prodAppOpenAdUnitId,
      'ca-app-pub-3463774223212169/9722406294',
    );
    expect(
      AdManager.prodInterstitialAdUnitId,
      'ca-app-pub-3463774223212169/9973602018',
    );
    expect(
      AdManager.prodRewardedAdUnitId,
      'ca-app-pub-3463774223212169/7096242958',
    );
  });
}
