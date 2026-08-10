// ignore_for_file: avoid_print
/// Run: flutter run -d windows -t tool/audio_hear_check.dart
import 'package:flutter/material.dart';
import 'package:hollow_hour/audio/audio_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AudioManager.instance.init();
  await AudioManager.instance.playMusic();
  runApp(const _AudioHearApp());
}

class _AudioHearApp extends StatelessWidget {
  const _AudioHearApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Audio hear-check',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
              const SizedBox(height: 8),
              const Text(
                'Music should already be looping.',
                style: TextStyle(color: Colors.white54),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => AudioManager.instance.playTap(),
                child: const Text('Play tap'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => AudioManager.instance.playPurchase(),
                child: const Text('Play purchase'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
