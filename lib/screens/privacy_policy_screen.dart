import 'package:flutter/material.dart';

import '../theme/themed_chrome.dart';

/// Local-only privacy policy — no network, ads, or analytics in this app.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: ThemedBackButton(
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            letterSpacing: 2,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hollow Hour Privacy Policy',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    letterSpacing: 1.2,
                    height: 1.35,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Hollow Hour does not collect, store, or share any personal '
                  'information. The app does not use analytics, advertising '
                  'networks, or third-party trackers. Your in-game progress '
                  '(Embers, unlocked characters, talent levels, and settings) '
                  'is stored only locally on your device and is never '
                  'transmitted anywhere. Uninstalling the app permanently '
                  'deletes this local data.\n\n'
                  'This app does not require an internet connection to function '
                  'and does not communicate with any external server.\n\n'
                  'Last updated: August 11, 2026',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 14,
                    height: 1.55,
                    letterSpacing: 0.2,
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  height: 1,
                  color: _maroon.withValues(alpha: 0.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
