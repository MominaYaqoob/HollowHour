import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';

import 'ads/ad_manager.dart';
import 'audio/audio_manager.dart';
import 'connectivity/connectivity_gate.dart';
import 'prefs/app_flags.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/economy_state.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AudioManager.instance.init();
  try {
    await MobileAds.instance
        .initialize()
        .timeout(const Duration(seconds: 8));
    await AdManager.instance.init().timeout(const Duration(seconds: 10));
  } catch (e, st) {
    debugPrint('Mobile Ads init failed: $e\n$st');
  }
  runApp(const HollowHourApp());
}

class HollowHourApp extends StatelessWidget {
  const HollowHourApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => EconomyState(),
      child: MaterialApp(
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
        builder: (context, child) => ConnectivityGate(
          child: child ?? const SizedBox.shrink(),
        ),
        home: const _RootGate(),
      ),
    );
  }
}

/// Loads economy + onboarding flag, then shows Onboarding or Splash.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  Future<bool>? _bootstrap;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bootstrap ??= _load();
  }

  Future<bool> _load() async {
    await context.read<EconomyState>().loadFromDisk();
    // Start ambient as early as possible (respects persisted Music switch).
    unawaited(AudioManager.instance.playMusic());
    return AppFlags.hasSeenOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0A),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF8B1A1A),
              ),
            ),
          );
        }
        final seen = snapshot.data ?? false;
        return seen ? const SplashScreen() : const OnboardingScreen();
      },
    );
  }
}
