import 'package:flutter/material.dart';

import '../theme/app_assets.dart';
import '../theme/field_backdrop.dart';
import 'character_select_screen.dart';
import 'how_to_play_overlay.dart';
import 'pre_game_setup_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';
import 'talent_tree_screen.dart';

/// Main menu for Hollow Hour — fog parallax, ember currency, and menu actions.
class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen>
    with TickerProviderStateMixin {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _fogController;
  late final AnimationController _lightController;
  late final AnimationController _entryController;
  late final AnimationController _chromePulseController;

  late final Animation<double> _fogNear;
  late final Animation<double> _fogFar;
  late final Animation<double> _fogOpacity;
  late final Animation<double> _lightPulse;
  late final Animation<double> _chromePulse;

  bool _showHowToPlay = false;

  @override
  void initState() {
    super.initState();

    _fogController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    )..repeat();

    // Parallax: far layer drifts slower than near.
    _fogFar = Tween<double>(begin: -0.08, end: 0.08).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogNear = Tween<double>(begin: 0.12, end: -0.12).animate(
      CurvedAnimation(parent: _fogController, curve: Curves.easeInOut),
    );
    _fogOpacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.22, end: 0.4), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.4, end: 0.18), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.3), weight: 1),
    ]).animate(_fogController);

    // Faint flickering maroon light in a corner.
    _lightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    )..repeat(reverse: true);

    _lightPulse = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.18, end: 0.42), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.42, end: 0.12), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.12, end: 0.35), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 0.35, end: 0.2), weight: 1),
    ]).animate(
      CurvedAnimation(parent: _lightController, curve: Curves.easeInOut),
    );

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _chromePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
    _chromePulse = CurvedAnimation(
      parent: _chromePulseController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _fogController.dispose();
    _lightController.dispose();
    _entryController.dispose();
    _chromePulseController.dispose();
    super.dispose();
  }

  void _open(Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 450),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: _charcoal,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const FieldBackdrop(showField: true, fogOpacity: 0.16),

          // Flickering maroon light — bottom-right corner.
          AnimatedBuilder(
            animation: _lightController,
            builder: (context, _) {
              return IgnorePointer(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0.95, 0.9),
                      radius: 0.85,
                      colors: [
                        _maroonGlow.withValues(alpha: _lightPulse.value),
                        _maroon.withValues(alpha: _lightPulse.value * 0.35),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.35, 1.0],
                    ),
                  ),
                ),
              );
            },
          ),

          // Fog parallax layers.
          AnimatedBuilder(
            animation: _fogController,
            builder: (context, _) {
              return Opacity(
                opacity: _fogOpacity.value,
                child: Stack(
                  children: [
                    Positioned(
                      left: _fogFar.value * size.width - size.width * 0.15,
                      top: size.height * 0.2,
                      child: _FogBlob(
                        width: size.width * 1.0,
                        height: size.height * 0.32,
                        color: const Color(0xFF242424),
                      ),
                    ),
                    Positioned(
                      left: _fogNear.value * size.width - size.width * 0.1,
                      top: size.height * 0.5,
                      child: _FogBlob(
                        width: size.width * 1.15,
                        height: size.height * 0.38,
                        color: const Color(0xFF1A1A1A),
                      ),
                    ),
                    Positioned(
                      left: _fogFar.value * size.width * 0.5,
                      bottom: size.height * 0.08,
                      child: _FogBlob(
                        width: size.width * 0.9,
                        height: size.height * 0.28,
                        color: const Color(0xFF202020),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Soft vignette.
          const IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.2,
                  colors: [
                    Colors.transparent,
                    Color(0x66000000),
                    Color(0xDD000000),
                  ],
                  stops: [0.4, 0.78, 1.0],
                ),
              ),
            ),
          ),

          // UI chrome.
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                children: [
                  AnimatedBuilder(
                    animation: _chromePulse,
                    builder: (context, _) {
                      return Row(
                        children: [
                          _EmberCurrency(
                            amount: 240,
                            pulse: _chromePulse.value,
                          ),
                          const Spacer(),
                          _ChromeIconButton(
                            onPressed: () =>
                                setState(() => _showHowToPlay = true),
                            pulse: _chromePulse.value,
                            child: Text(
                              '?',
                              style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                height: 1,
                                color: Colors.white.withValues(alpha: 0.82),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          _ChromeIconButton(
                            onPressed: () => _open(const SettingsScreen()),
                            pulse: _chromePulse.value,
                            child: Image.asset(
                              AppAssets.iconSettings,
                              width: 18,
                              height: 18,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Image.asset(
                    AppAssets.brandingLogo,
                    width: MediaQuery.sizeOf(context).width * 0.62,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                  const Spacer(flex: 2),
                  _MenuButton(
                    label: 'Play',
                    primary: true,
                    width: 220,
                    height: 56,
                    entry: _entryController,
                    stagger: 0.0,
                    onTap: () => _open(const PreGameSetupScreen()),
                  ),
                  const SizedBox(height: 18),
                  _MenuButton(
                    label: 'Characters',
                    width: 190,
                    height: 46,
                    entry: _entryController,
                    stagger: 0.12,
                    onTap: () => _open(const CharacterSelectScreen()),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Talents',
                    width: 170,
                    height: 42,
                    entry: _entryController,
                    stagger: 0.24,
                    onTap: () => _open(const TalentTreeScreen()),
                  ),
                  const SizedBox(height: 14),
                  _MenuButton(
                    label: 'Shop',
                    width: 190,
                    height: 46,
                    entry: _entryController,
                    stagger: 0.36,
                    onTap: () => _open(const ShopScreen()),
                  ),
                  const Spacer(flex: 3),
                  Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 11,
                      letterSpacing: 1.5,
                      color: Colors.white.withValues(alpha: 0.18),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),

          HowToPlayOverlay(
            visible: _showHowToPlay,
            onDismiss: () => setState(() => _showHowToPlay = false),
          ),
        ],
      ),
    );
  }
}

class _EmberCurrency extends StatelessWidget {
  const _EmberCurrency({
    required this.amount,
    required this.pulse,
  });

  final int amount;
  final double pulse;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final glow = 0.22 + pulse * 0.28;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 14, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Color.lerp(
            _maroon.withValues(alpha: 0.45),
            _maroonGlow.withValues(alpha: 0.85),
            pulse,
          )!,
        ),
        boxShadow: [
          BoxShadow(
            color: _maroonGlow.withValues(alpha: glow),
            blurRadius: 12 + pulse * 8,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: 1.0 + pulse * 0.06,
            child: Image.asset(
              AppAssets.iconEmbers,
              width: 18,
              height: 18,
              errorBuilder: (_, _, _) => Icon(
                Icons.local_fire_department,
                size: 18,
                color: _maroonGlow.withValues(alpha: 0.9),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Embers',
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 12,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.55),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$amount',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: Color.lerp(
                Colors.white.withValues(alpha: 0.9),
                const Color(0xFFFFC9C9),
                pulse * 0.5,
              ),
              shadows: [
                Shadow(
                  color: _maroonGlow.withValues(alpha: 0.45 + pulse * 0.25),
                  blurRadius: 8,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChromeIconButton extends StatefulWidget {
  const _ChromeIconButton({
    required this.onPressed,
    required this.child,
    required this.pulse,
  });

  final VoidCallback onPressed;
  final Widget child;
  final double pulse;

  @override
  State<_ChromeIconButton> createState() => _ChromeIconButtonState();
}

class _ChromeIconButtonState extends State<_ChromeIconButton>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _press;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.88), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.88, end: 1.0), weight: 1.2),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _press.forward(from: 0);
    if (!mounted) return;
    widget.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final pulse = widget.pulse;
    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale.value,
            child: child,
          );
        },
        child: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.black.withValues(alpha: 0.4),
            border: Border.all(
              color: Color.lerp(
                Colors.white.withValues(alpha: 0.18),
                _maroonGlow.withValues(alpha: 0.75),
                pulse * 0.7,
              )!,
            ),
            boxShadow: [
              BoxShadow(
                color: _maroon.withValues(alpha: 0.18 + pulse * 0.22),
                blurRadius: 10 + pulse * 6,
              ),
            ],
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

class _MenuButton extends StatefulWidget {
  const _MenuButton({
    required this.label,
    required this.onTap,
    required this.entry,
    required this.stagger,
    this.primary = false,
    this.width = 190,
    this.height = 46,
  });

  final String label;
  final VoidCallback onTap;
  final AnimationController entry;
  final double stagger;
  final bool primary;
  final double width;
  final double height;

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton>
    with TickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _press;
  late final AnimationController _idle;
  late final Animation<double> _pressScale;
  late final Animation<double> _pressGlow;
  late final Animation<double> _idleGlow;
  late final Animation<double> _entryOpacity;
  late final Animation<Offset> _entrySlide;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _pressScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.94)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.94, end: widget.primary ? 1.05 : 1.02)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1.4,
      ),
      TweenSequenceItem(
        tween: Tween(begin: widget.primary ? 1.05 : 1.02, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 0.8,
      ),
    ]).animate(_press);

    _pressGlow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1.4),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));

    _idle = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.primary ? 1800 : 2600),
    )..repeat(reverse: true);
    _idleGlow = CurvedAnimation(parent: _idle, curve: Curves.easeInOut);

    final start = widget.stagger.clamp(0.0, 0.7);
    final end = (start + 0.45).clamp(0.0, 1.0);
    _entryOpacity = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: widget.entry,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    _entrySlide = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: widget.entry,
        curve: Interval(start, end, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _press.dispose();
    _idle.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _press.forward(from: 0);
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final borderWidth = widget.primary ? 1.8 : 1.2;
    final fontSize = widget.primary ? 22.0 : 16.0;
    final letterSpacing = widget.primary ? 5.0 : 3.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_press, _idle, widget.entry]),
      builder: (context, _) {
        final idle = widget.primary
            ? 0.35 + _idleGlow.value * 0.45
            : 0.18 + _idleGlow.value * 0.22;
        final glow = (idle + _pressGlow.value * 0.65).clamp(0.0, 1.0);
        return FadeTransition(
          opacity: _entryOpacity,
          child: SlideTransition(
            position: _entrySlide,
            child: GestureDetector(
              onTap: _handleTap,
              child: Transform.scale(
                scale: _pressScale.value,
                child: Container(
                  width: widget.width,
                  height: widget.height,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.04),
                        Colors.black.withValues(alpha: 0.55),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: Color.lerp(
                        _maroon.withValues(
                          alpha: widget.primary ? 0.7 : 0.4,
                        ),
                        _maroonGlow,
                        glow,
                      )!,
                      width: borderWidth,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _maroonGlow.withValues(
                          alpha: (widget.primary ? 0.32 : 0.16) * glow,
                        ),
                        blurRadius: (widget.primary ? 20 : 12) * glow,
                        spreadRadius: (widget.primary ? 1.2 : 0.4) * glow,
                      ),
                    ],
                  ),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: fontSize,
                      fontWeight:
                          widget.primary ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: letterSpacing,
                      color: Color.lerp(
                        Colors.white.withValues(alpha: 0.9),
                        const Color(0xFFFFE8E8),
                        glow * 0.35,
                      ),
                      shadows: [
                        Shadow(
                          color: _maroonGlow.withValues(alpha: 0.45 * glow),
                          blurRadius: 8 * glow,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
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
            color: color.withValues(alpha: 0.55),
            blurRadius: 55,
            spreadRadius: 28,
          ),
        ],
      ),
    );
  }
}
