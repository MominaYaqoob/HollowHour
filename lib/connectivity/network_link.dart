import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Shared link probe for ads only — never used to block gameplay.
bool connectivityResultsOnline(List<ConnectivityResult> results) {
  return results.any((r) => r != ConnectivityResult.none);
}

class NetworkLink {
  NetworkLink._();

  /// Fail-open if the plugin throws so a broken check cannot stall ads forever.
  static Future<bool> isOnline() async {
    try {
      final results = await Connectivity().checkConnectivity();
      return connectivityResultsOnline(results);
    } catch (e, st) {
      debugPrint('NetworkLink check failed: $e\n$st');
      return true;
    }
  }
}
