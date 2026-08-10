import 'package:flutter/material.dart';

import '../audio/audio_manager.dart';
import '../theme/app_assets.dart';
import '../theme/themed_chrome.dart';

/// Settings — audio toggles wired to [AudioManager] (persisted).
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late bool _sfx;
  late bool _music;
  bool _vibration = true;

  @override
  void initState() {
    super.initState();
    final audio = AudioManager.instance;
    _sfx = audio.sfxEnabled;
    _music = audio.musicEnabled;
  }

  Future<void> _confirmReset() async {
    AudioManager.instance.playTap();
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF121010),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: _maroon.withValues(alpha: 0.55)),
          ),
          title: Text(
            'Reset Progress',
            style: TextStyle(
              fontFamily: 'serif',
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          content: Text(
            'Are you sure? This cannot be undone.',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                AudioManager.instance.playTap();
                Navigator.of(context).pop();
              },
              child: Text(
                'Cancel',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                AudioManager.instance.playTap();
                Navigator.of(context).pop();
              },
              child: Text(
                'Reset',
                style: TextStyle(
                  fontFamily: 'serif',
                  color: _maroonGlow.withValues(alpha: 0.95),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

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
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ThemedUiIcon(AppAssets.iconSettings, size: 20),
            const SizedBox(width: 8),
            Text(
              'Settings',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 18,
                letterSpacing: 3,
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          _sectionLabel('Audio'),
          const SizedBox(height: 8),
          _ToggleRow(
            label: 'Sound Effects',
            value: _sfx,
            onChanged: (v) async {
              setState(() => _sfx = v);
              await AudioManager.instance.setSfxEnabled(v);
              if (v) AudioManager.instance.playTap();
            },
          ),
          _ToggleRow(
            label: 'Music',
            value: _music,
            onChanged: (v) async {
              setState(() => _music = v);
              await AudioManager.instance.setMusicEnabled(v);
            },
          ),
          const SizedBox(height: 20),
          _sectionLabel('Device'),
          const SizedBox(height: 8),
          _ToggleRow(
            label: 'Vibration',
            value: _vibration,
            onChanged: (v) => setState(() => _vibration = v),
          ),
          const SizedBox(height: 28),
          _sectionLabel('Danger Zone'),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _confirmReset,
            style: OutlinedButton.styleFrom(
              foregroundColor: _maroonGlow.withValues(alpha: 0.85),
              side: BorderSide(color: _maroon.withValues(alpha: 0.65)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: const Text(
              'Reset Progress',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 14,
                letterSpacing: 2,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _sectionLabel('About'),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        AppAssets.brandingIcon,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Hollow Hour',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 16,
                          letterSpacing: 2,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'A dark horror-survival experience. UI demo for presentation — the Hollow waits.',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 12,
                    height: 1.45,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 11,
        letterSpacing: 2,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 15,
                letterSpacing: 1,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: _maroonGlow,
            activeTrackColor: _maroon.withValues(alpha: 0.55),
            inactiveThumbColor: Colors.white38,
            inactiveTrackColor: Colors.white12,
          ),
        ],
      ),
    );
  }
}
