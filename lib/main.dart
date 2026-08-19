import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'audio/audio_manager.dart';
import 'connectivity/connectivity_gate.dart';
import 'prefs/app_flags.dart';
import 'screens/agree_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/economy_state.dart';
import 'theme/maroon_loader.dart';

/// Bump with [pubspec] version so each new APK starts a clean save (not resume).
const _installStamp = '1.0.0+2';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await _ensureFreshInstallIfNeeded();
  await AudioManager.instance.init();
  // Ads start only after agree / onboarding (see SplashScreen).
  runApp(const HollowHourApp());
}

Future<void> _ensureFreshInstallIfNeeded() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('app_install_stamp') != _installStamp) {
      await prefs.clear();
      await prefs.setString('app_install_stamp', _installStamp);
    }
  } catch (e, st) {
    debugPrint('Fresh-install check failed: $e\n$st');
  }
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

/// Loads economy + consent / onboarding flags, then shows the right first screen.
class _RootGate extends StatefulWidget {
  const _RootGate();

  @override
  State<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends State<_RootGate> {
  Future<({bool agreed, bool onboarded})>? _bootstrap;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _bootstrap ??= _load();
  }

  Future<({bool agreed, bool onboarded})> _load() async {
    await context.read<EconomyState>().loadFromDisk();
    // Start ambient as early as possible (respects persisted Music switch).
    unawaited(AudioManager.instance.playMusic());
    final agreed = await AppFlags.hasAgreedTerms();
    final onboarded = await AppFlags.hasSeenOnboarding();
    return (agreed: agreed, onboarded: onboarded);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<({bool agreed, bool onboarded})>(
      future: _bootstrap,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaroonLoaderScaffold();
        }
        final data = snapshot.data ?? (agreed: false, onboarded: false);
        if (!data.agreed) return const AgreeScreen();
        if (!data.onboarded) return const OnboardingScreen();
        return const SplashScreen();
      },
    );
  }
}
