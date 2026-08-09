import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'prefs/app_flags.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const HollowHourApp());
}

class HollowHourApp extends StatelessWidget {
  const HollowHourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hollow Hour',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8B1A1A),
          brightness: Brightness.dark,
        ),
      ),
      home: const _RootGate(),
    );
  }
}

/// Loads onboarding flag, then shows Onboarding or Splash.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  late final Future<bool> _hasSeenOnboarding;

  @override
  void initState() {
    super.initState();
    _hasSeenOnboarding = AppFlags.hasSeenOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasSeenOnboarding,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: SizedBox.expand(),
          );
        }
        final seen = snapshot.data ?? false;
        return seen ? const SplashScreen() : const OnboardingScreen();
      },
    );
  }
}
