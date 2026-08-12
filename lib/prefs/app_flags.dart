import 'package:shared_preferences/shared_preferences.dart';

/// Simple boolean flags only — onboarding / tutorial seen.
class AppFlags {
  AppFlags._();

  static const hasSeenOnboardingKey = 'hasSeenOnboarding';
  static const hasSeenTutorialKey = 'hasSeenTutorial';
  static const hasSeenControlsHintKey = 'hasSeenControlsHint';

  static Future<bool> hasSeenOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasSeenOnboardingKey) ?? false;
  }

  static Future<void> setHasSeenOnboarding(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenOnboardingKey, value);
  }

  static Future<bool> hasSeenTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasSeenTutorialKey) ?? false;
  }

  static Future<void> setHasSeenTutorial(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenTutorialKey, value);
  }

  static Future<bool> hasSeenControlsHint() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(hasSeenControlsHintKey) ?? false;
  }

  static Future<void> setHasSeenControlsHint(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hasSeenControlsHintKey, value);
  }
}
