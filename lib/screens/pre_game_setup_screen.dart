import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import 'gameplay_hud_screen.dart';

enum GameMode { standard, quick, endless }

class _WeaponOption {
  const _WeaponOption({
    required this.name,
    required this.icon,
    required this.locked,
  });

  final String name;
  final IconData icon;
  final bool locked;
}

/// Pre-game setup — character preview, weapon, mode, and Hollow Depth.
class PreGameSetupScreen extends StatefulWidget {
  const PreGameSetupScreen({
    super.key,
    this.characterName = 'Wanderer',
    this.portraitAsset = AppAssets.charWanderer,
  });

  final String characterName;
  final String portraitAsset;

  @override
  State<PreGameSetupScreen> createState() => _PreGameSetupScreenState();
}

class _PreGameSetupScreenState extends State<PreGameSetupScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  static const List<_WeaponOption> _weapons = [
    _WeaponOption(
      name: 'Rust Blade',
      icon: Icons.sports_martial_arts,
      locked: false,
    ),
    _WeaponOption(
      name: 'Ember Pistol',
      icon: Icons.flare,
      locked: false,
    ),
    _WeaponOption(
      name: 'Grave Axe',
      icon: Icons.hardware_outlined,
      locked: true,
    ),
    _WeaponOption(
      name: 'Void Staff',
      icon: Icons.auto_awesome,
      locked: true,
    ),
    _WeaponOption(
      name: 'Hollow Bow',
      icon: Icons.north_east,
      locked: true,
    ),
  ];

  late final AnimationController _fogController;
  late final Animation<double> _fogDrift;
  late final Animation<double> _fogOpacity;

  int _selectedWeapon = 0;
  GameMode _mode = GameMode.standard;
  double _hollowDepth = 5;

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
                    name: widget.characterName,
                    portraitAsset: widget.portraitAsset,
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
                        return _WeaponChip(
                          weapon: weapon,
                          selected: _selectedWeapon == index,
                          onTap: weapon.locked
                              ? null
                              : () => setState(() => _selectedWeapon = index),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionLabel('Game Mode'),
                  const SizedBox(height: 12),
                  _ModeSegmentedControl(
                    value: _mode,
                    onChanged: (mode) => setState(() => _mode = mode),
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      const Expanded(child: _SectionLabel('Hollow Depth')),
                      Text(
                        '${_hollowDepth.round()}',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 18,
                          letterSpacing: 1,
                          color: _maroonGlow.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _maroon,
                      inactiveTrackColor: Colors.white.withValues(alpha: 0.1),
                      thumbColor: _maroonGlow,
                      overlayColor: _maroonGlow.withValues(alpha: 0.2),
                      trackHeight: 4,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                      valueIndicatorColor: _maroon,
                      valueIndicatorTextStyle: const TextStyle(
                        fontFamily: 'serif',
                        fontSize: 12,
                      ),
                    ),
                    child: Slider(
                      value: _hollowDepth,
                      min: 1,
                      max: 15,
                      divisions: 14,
                      label: '${_hollowDepth.round()}',
                      onChanged: (value) {
                        setState(() => _hollowDepth = value);
                      },
                    ),
                  ),
                  Text(
                    'Difficulty',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      letterSpacing: 1,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const Spacer(),
                  _BeginButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const GameplayHudScreen(),
                          transitionsBuilder: (
                            context,
                            animation,
                            secondaryAnimation,
                            child,
                          ) {
                            return FadeTransition(
                              opacity: animation,
                              child: child,
                            );
                          },
                          transitionDuration: const Duration(milliseconds: 600),
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
    required this.selected,
    required this.onTap,
  });

  final _WeaponOption weapon;
  final bool selected;
  final VoidCallback? onTap;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final locked = weapon.locked;
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

class _ModeSegmentedControl extends StatelessWidget {
  const _ModeSegmentedControl({
    required this.value,
    required this.onChanged,
  });

  final GameMode value;
  final ValueChanged<GameMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          for (final mode in GameMode.values)
            Expanded(
              child: _ModeSegment(
                label: switch (mode) {
                  GameMode.standard => 'Standard',
                  GameMode.quick => 'Quick',
                  GameMode.endless => 'Endless',
                },
                selected: value == mode,
                onTap: () => onChanged(mode),
              ),
            ),
        ],
      ),
    );
  }
}

class _ModeSegment extends StatelessWidget {
  const _ModeSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? _maroon.withValues(alpha: 0.35)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _maroonGlow.withValues(alpha: 0.25),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 13,
            letterSpacing: 1,
            color: selected
                ? Colors.white.withValues(alpha: 0.95)
                : Colors.white.withValues(alpha: 0.45),
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
