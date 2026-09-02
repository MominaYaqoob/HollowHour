import 'dart:ui' show FakeViewPadding;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hollow_hour/screens/main_menu_screen.dart';
import 'package:hollow_hour/state/economy_state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('main menu chrome sits below 44px notch plus 16dp', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1.0;
    tester.view.padding = const FakeViewPadding(top: 44);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => EconomyState(),
        child: const MaterialApp(home: MainMenuScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final embers = find.text('Embers');
    expect(embers, findsOneWidget);
    // SafeArea inset 44 + extra 16.
    expect(tester.getTopLeft(embers).dy, greaterThanOrEqualTo(60));
  });
}
