import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ads/ad_manager.dart';
import '../ads/native_ad_widget.dart';
import '../audio/audio_manager.dart';
import '../game/game_mode.dart';
import '../state/economy_state.dart';
import '../theme/app_assets.dart';
import 'gameplay_hud_screen.dart';

export '../game/game_mode.dart'
    show GameMode, stageDurationForLevel, stageDepthForLevel, stageDurationLabel;

class _WeaponOption {
  const _WeaponOption({
    required this.id,
    required this.name,
    required this.icon,
  });

  final String id;
  final String name;
  final IconData icon;
}

class _CharacterLoadout {
  const _CharacterLoadout({
    required this.name,
    required this.portraitAsset,
  });

  final String name;
  final String portraitAsset;
}

/// Pre-game setup — character preview, weapon, and selected stage level.
class PreGameSetupScreen extends StatefulWidget {
  const PreGameSetupScreen({
    super.key,
    this.stageLevel = 1,
  });

  /// Campaign stage to play (1–30). Duration + difficulty derived from this.
  final int stageLevel;

  @override
  State<PreGameSetupScreen> createState() => _PreGameSetupScreenState();
}

class _PreGameSetupScreenState extends State<PreGameSetupScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  static const Map<String, _CharacterLoadout> _characters = {
    'wanderer': _CharacterLoadout(
      name: 'Wanderer',
      portraitAsset: AppAssets.charWanderer,
    ),
    'huntress': _CharacterLoadout(
      name: 'Huntress',
      portraitAsset: AppAssets.charHuntress,
    ),
    'scholar': _CharacterLoadout(
      name: 'Scholar',
      portraitAsset: AppAssets.charScholar,
    ),
    'brute': _CharacterLoadout(
      name: 'Brute',
      portraitAsset: AppAssets.charBrute,
    ),
    'ghost': _CharacterLoadout(
      name: 'Ghost',
      portraitAsset: AppAssets.charGhost,
    ),
  };

  static const List<_WeaponOption> _weapons = [
    _WeaponOption(
      id: 'blade',
      name: 'Rust Blade',
      icon: Icons.sports_martial_arts,
    ),
    _WeaponOption(
      id: 'pistol',
      name: 'Ember Pistol',
      icon: Icons.flare,
    ),
    _WeaponOption(
      id: 'axe',
      name: 'Grave Axe',
      icon: Icons.hardware_outlined,
    ),
    _WeaponOption(
      id: 'staff',
      name: 'Void Staff',
      icon: Icons.auto_awesome,
    ),
    _WeaponOption(
      id: 'bow',
      name: 'Hollow Bow',
      icon: Icons.north_east,
    ),
  ];

  late final AnimationController _fogController;
  late final Animation<double> _fogDrift;
  late final Animation<double> _fogOpacity;

  int get _stageLevel => widget.stageLevel.clamp(1, 30);

  @override
  void initState() {
    super.initState();
    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();

    _fogDrift = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.15, end: 0.3), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.22), weight: 1),
    ]).animate(_fogController);
  }

  @override
  void dispose() {
    _fogController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final economy = context.watch<EconomyState>();
    final characterId = economy.equippedCharacterId ?? 'wanderer';
    final character = _characters[characterId] ?? _characters['wanderer']!;
    final selectedWeaponId = economy.equippedWeaponId ?? 'blade';
    final selectedWeaponIndex = _weapons
        .indexWhere((w) => w.id == selectedWeaponId)
        .clamp(0, _weapons.length - 1);

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _maroon),
        title: Text(
          'Prepare',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 18,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: _charcoal),
          AnimatedBuilder(
            animation: _fogController,
            builder: (context, _) {
              return Opacity(
                opacity: _fogOpacity.value,
                child: Stack(
                  children: [
                    Positioned(
                      left: _fogDrift.value * size.width - size.width * 0.2,
                      top: size.height * 0.25,
                      child: _FogBlob(
                        width: size.width * 0.95,
                        height: size.height * 0.28,
                        color: const Color(0xFF222222),
                      ),
                    ),
                    Positioned(
                      left: -_fogDrift.value * size.width,
                      bottom: size.height * 0.15,
                      child: _FogBlob(
                        width: size.width * 1.05,
                        height: size.height * 0.3,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _CharacterPreview(
                    name: character.name,
                    portraitAsset: character.portraitAsset,
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('Weapon'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _weapons.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, index) {
                        final weapon = _weapons[index];
                        final locked = !economy.ownsWeapon(weapon.id);
                        return _WeaponChip(
                          weapon: weapon,
                          locked: locked,
                          selected: selectedWeaponIndex == index,
                          onTap: locked
                              ? null
                              : () => economy.equipWeapon(weapon.id),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('Stage'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Level $_stageLevel',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 16,
                            letterSpacing: 1.2,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Survive ${stageDurationLabel(_stageLevel)}',
                          style: TextStyle(
                            fontFamily: 'serif',
                            fontSize: 13,
                            letterSpacing: 1,
                            color: _maroonGlow.withValues(alpha: 0.95),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  NativeAdWidget(
                    adUnitId: AdManager.testNativeAdUnitId,
                    height: 168,
                    format: NativeAdFormat.small,
                    ensureInitialized: AdManager.instance.ensureInitialized,
                  ),
                  const SizedBox(height: 12),
                  _BeginButton(
                    onPressed: () {
                      final level = _stageLevel;
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  GameplayHudScreen(stageLevel: level),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            return _FogMatchEnterTransition(
                              animation: animation,
                              child: child,
                            );
                          },
                          transitionDuration:
                              const Duration(milliseconds: 1100),
                        ),
                      );
                    },
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontFamily: 'serif',
        fontSize: 12,
        letterSpacing: 2,
        color: Colors.white.withValues(alpha: 0.45),
      ),
    );
  }
}

class _CharacterPreview extends StatelessWidget {
  const _CharacterPreview({
    required this.name,
    required this.portraitAsset,
  });

  final String name;
  final String portraitAsset;

  static const Color _maroon = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: _maroon.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: _maroon.withValues(alpha: 0.25),
                blurRadius: 12,
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(portraitAsset, fit: BoxFit.cover),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selected',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 11,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.35),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                name,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 22,
                  letterSpacing: 1.5,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WeaponChip extends StatelessWidget {
  const _WeaponChip({
    required this.weapon,
    required this.locked,
    required this.selected,
    required this.onTap,
  });

  final _WeaponOption weapon;
  final bool locked;
  final bool selected;
  final VoidCallback? onTap;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final active = selected && !locked;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.45 : 1,
        child: Container(
          width: 64,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: active
                  ? _maroonGlow
                  : Colors.white.withValues(alpha: locked ? 0.08 : 0.15),
              width: active ? 1.6 : 1,
            ),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: _maroonGlow.withValues(alpha: 0.35),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      weapon.icon,
                      size: 26,
                      color: locked
                          ? Colors.white38
                          : active
                              ? _maroonGlow
                              : Colors.white70,
                    ),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        weapon.name.split(' ').last,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 9,
                          letterSpacing: 0.5,
                          color: Colors.white.withValues(
                            alpha: locked ? 0.35 : 0.65,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (locked)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.7),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: Image.asset(AppAssets.iconLock, fit: BoxFit.contain),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BeginButton extends StatefulWidget {
  const _BeginButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  State<_BeginButton> createState() => _BeginButtonState();
}

class _BeginButtonState extends State<_BeginButton>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );

    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: 1.05)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1.2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.05, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.8,
      ),
    ]).animate(_controller);

    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.4), weight: 1.5),
    ]).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    AudioManager.instance.playTap();
    await _controller.forward(from: 0);
    if (!mounted) return;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final glow = _glow.value;
          return Transform.scale(
            scale: _scale.value,
            child: Container(
              width: double.infinity,
              height: 56,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Color.lerp(_maroon, _maroonGlow, glow)!,
                  width: 1.8,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _maroonGlow.withValues(alpha: 0.35 * glow + 0.15),
                    blurRadius: 18 * glow + 6,
                    spreadRadius: 1 * glow,
                  ),
                ],
              ),
              child: Text(
                'Begin the Hour',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2.5,
                  color: Colors.white.withValues(alpha: 0.92),
                  shadows: [
                    Shadow(
                      color: _maroonGlow.withValues(alpha: 0.55 * glow),
                      blurRadius: 10 * glow,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FogBlob extends StatelessWidget {
  const _FogBlob({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(height),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 50,
            spreadRadius: 24,
          ),
        ],
      ),
    );
  }
}

/// Prepare → HUD: fog rises mid-transition, then clears into the match.
class _FogMatchEnterTransition extends StatelessWidget {
  const _FogMatchEnterTransition({
    required this.animation,
    required this.child,
  });

  final Animation<double> animation;
  final Widget child;

  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeInOutCubic,
    );

    return AnimatedBuilder(
      animation: curved,
      builder: (context, _) {
        final t = curved.value;
        // Fog peaks around mid-transition, then dissolves.
        final fog = (1.0 - ((t - 0.48).abs() * 2.15)).clamp(0.0, 1.0);
        final childOpacity = Interval(0.38, 1.0, curve: Curves.easeOut)
            .transform(t);

        return Stack(
          fit: StackFit.expand,
          children: [
            Opacity(
              opacity: childOpacity,
              child: child,
            ),
            IgnorePointer(
              child: Opacity(
                opacity: fog,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, 0.15),
                      radius: 1.15,
                      colors: [
                        const Color(0xFF2A2222).withValues(alpha: 0.55),
                        _charcoal.withValues(alpha: 0.88),
                        _charcoal,
                      ],
                      stops: const [0.0, 0.45, 1.0],
                    ),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Align(
                        alignment: Alignment(0, -0.2 + t * 0.15),
                        child: Container(
                          width: MediaQuery.sizeOf(context).width * 1.2,
                          height: MediaQuery.sizeOf(context).height * 0.4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(200),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3A3030)
                                    .withValues(alpha: 0.55),
                                blurRadius: 70,
                                spreadRadius: 40,
                              ),
                              BoxShadow(
                                color: _maroon.withValues(alpha: 0.12),
                                blurRadius: 50,
                                spreadRadius: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
