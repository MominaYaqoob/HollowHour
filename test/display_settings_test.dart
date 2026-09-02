import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/prefs/display_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    DisplaySettings.instance.brightness = DisplaySettings.defaultBrightness;
  });

  test('brightness clamps to 0.5–1.5 and persists', () async {
    await DisplaySettings.instance.setBrightness(0.2);
    expect(DisplaySettings.instance.brightness, DisplaySettings.minBrightness);
    expect(DisplaySettings.instance.darkenOpacity, greaterThan(0));
    expect(DisplaySettings.instance.brightenOpacity, 0);

    await DisplaySettings.instance.setBrightness(2.0);
    expect(DisplaySettings.instance.brightness, DisplaySettings.maxBrightness);
    expect(DisplaySettings.instance.brightenOpacity, greaterThan(0));
    expect(DisplaySettings.instance.darkenOpacity, 0);

    await DisplaySettings.instance.setBrightness(1.0);
    expect(DisplaySettings.instance.darkenOpacity, 0);
    expect(DisplaySettings.instance.brightenOpacity, 0);

    SharedPreferences.setMockInitialValues({
      DisplaySettings.prefsKey: 1.25,
    });
    await DisplaySettings.instance.load();
    expect(DisplaySettings.instance.brightness, 1.25);
  });
}
