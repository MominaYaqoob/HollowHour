import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/connectivity/network_link.dart';

void main() {
  test('wifi or mobile counts as online', () {
    expect(
      connectivityResultsOnline(const [ConnectivityResult.wifi]),
      isTrue,
    );
    expect(
      connectivityResultsOnline(const [ConnectivityResult.mobile]),
      isTrue,
    );
  });

  test('none / empty counts as offline', () {
    expect(
      connectivityResultsOnline(const [ConnectivityResult.none]),
      isFalse,
    );
    expect(connectivityResultsOnline(const []), isFalse);
  });
}
