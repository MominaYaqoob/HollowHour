import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'audio/audio_manager.dart';
import 'prefs/app_flags.dart';
import 'prefs/display_settings.dart';
import 'screens/agree_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'state/economy_state.dart';
import 'theme/maroon_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await AudioManager.instance.init();
  await DisplaySettings.instance.load();
  // Ads start only after agree / onboarding (see SplashScreen).
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
    // Chrome debug: reopen Agree so localhost can preview that screen.
    if (kDebugMode && kIsWeb) {
      await AppFlags.setHasAgreedTerms(false);
    }
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
