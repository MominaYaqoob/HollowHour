import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Gameplay brightness / gamma (0.5–1.5). Same persist pattern as audio toggles.
class DisplaySettings extends ChangeNotifier {
  DisplaySettings._();
  static final DisplaySettings instance = DisplaySettings._();

  static const prefsKey = 'display_brightness';
  static const minBrightness = 0.5;
  static const maxBrightness = 1.5;
  static const defaultBrightness = 1.0;

  double brightness = defaultBrightness;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      brightness = (prefs.getDouble(prefsKey) ?? defaultBrightness)
          .clamp(minBrightness, maxBrightness);
      notifyListeners();
    } catch (e) {
      debugPrint('DisplaySettings.load failed: $e');
    }
  }

  Future<void> setBrightness(double value) async {
    brightness = value.clamp(minBrightness, maxBrightness);
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(prefsKey, brightness);
    } catch (e) {
      debugPrint('DisplaySettings.setBrightness failed: $e');
    }
  }

  /// Black overlay when dimming below 1.0.
  double get darkenOpacity =>
      brightness >= 1.0 ? 0.0 : (1.0 - brightness) * 0.5;

  /// White overlay when lifting above 1.0.
  double get brightenOpacity =>
      brightness <= 1.0 ? 0.0 : (brightness - 1.0) * 0.28;
}
