import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:hollow_hour/audio/audio_manager.dart';
import 'package:hollow_hour/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await AudioManager.instance.init();
  });

  testWidgets('Onboarding shows when flag is unset', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const HollowHourApp());
    // Allow FutureBuilder + first frame (avoid pumpAndSettle — fog loops forever).
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Enter the Hollow'), findsOneWidget);
  });

  testWidgets('Splash shows when onboarding already seen', (tester) async {
    SharedPreferences.setMockInitialValues({'hasSeenOnboarding': true});
    await tester.pumpWidget(const HollowHourApp());
    await tester.pump();
    // Icon entrance, then delayed "Tap to Begin" (~700ms).
    await tester.pump(const Duration(milliseconds: 800));
    expect(find.byType(Image), findsWidgets);
    expect(find.text('Tap to Begin'), findsOneWidget);
  });
}
