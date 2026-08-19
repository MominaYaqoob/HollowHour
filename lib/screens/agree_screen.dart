import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../audio/audio_manager.dart';
import '../prefs/app_flags.dart';
import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

/// First-launch privacy / terms consent — themed to Hollow Hour chrome.
class AgreeScreen extends StatefulWidget {
  const AgreeScreen({super.key});

  static const privacyPolicyUrl =
      'https://learnwithfunpuzzlegame.blogspot.com/2026/08/hollow-hour.html';

  @override
  State<AgreeScreen> createState() => _AgreeScreenState();
}

class _AgreeScreenState extends State<AgreeScreen> {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  bool _agreed = false;
  bool _busy = false;

  Future<void> _openPrivacy() async {
    AudioManager.instance.playTap();
    try {
      final uri = Uri.parse(AgreeScreen.privacyPolicyUrl);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _continue() async {
    if (!_agreed || _busy) return;
    setState(() => _busy = true);
    AudioManager.instance.playTap();
    await AppFlags.setHasAgreedTerms(true);
    if (!mounted) return;

    final seenOnboarding = await AppFlags.hasSeenOnboarding();
    if (!mounted) return;

    final next = seenOnboarding
        ? const SplashScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => next,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FieldBackdrop(
            showField: true,
            fogOpacity: 0.2,
            fieldOpacity: 0.75,
          ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(0, -0.2),
                  radius: 1.05,
                  colors: [
                    _maroon.withValues(alpha: 0.14),
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.55),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  Image.asset(
                    AppAssets.brandingLogo,
                    height: 56,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Text(
                      'HOLLOW HOUR',
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 26,
                        letterSpacing: 3,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Before You Enter',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 24,
                      letterSpacing: 1.4,
                      color: Colors.white.withValues(alpha: 0.92),
                      shadows: [
                        Shadow(
                          color: _maroonGlow.withValues(alpha: 0.45),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'This game may show ads and stores progress on your device. '
                    'Please review the Privacy Policy, then agree to continue.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 13,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.42),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _maroon.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: Checkbox(
                            value: _agreed,
                            activeColor: _maroonGlow,
                            checkColor: Colors.white,
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            onChanged: _busy
                                ? null
                                : (v) {
                                    AudioManager.instance.playTap();
                                    setState(() => _agreed = v ?? false);
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                Text(
                                  'I agree to the ',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: _openPrivacy,
                                  child: Text(
                                    'Privacy Policy',
                                    style: TextStyle(
                                      fontFamily: 'serif',
                                      fontSize: 13,
                                      height: 1.4,
                                      color: _maroonGlow.withValues(
                                        alpha: 0.95,
                                      ),
                                      decoration: TextDecoration.underline,
                                      decorationColor: _maroonGlow.withValues(
                                        alpha: 0.7,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  '.',
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: 13,
                                    height: 1.4,
                                    color: Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _agreed && !_busy ? _continue : null,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.92),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.28),
                        side: BorderSide(
                          color: _agreed
                              ? _maroonGlow.withValues(alpha: 0.75)
                              : Colors.white.withValues(alpha: 0.18),
                        ),
                        backgroundColor: _agreed
                            ? _maroon.withValues(alpha: 0.28)
                            : Colors.black.withValues(alpha: 0.25),
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 15,
                          letterSpacing: 2,
                          color: _agreed
                              ? Colors.white.withValues(alpha: 0.92)
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
