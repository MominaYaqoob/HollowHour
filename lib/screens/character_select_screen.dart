import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_manager.dart';
import '../state/economy_state.dart';
import '../theme/app_assets.dart';
import 'pre_game_setup_screen.dart';

/// Character roster entry used by the select carousel.
class GameCharacter {
  const GameCharacter({
    required this.id,
    required this.name,
    required this.hp,
    required this.speed,
    required this.abilityIcon,
    required this.abilityName,
    required this.portraitAsset,
    required this.lockedPortraitAsset,
    this.unlockCost = 0,
  });

  final String id;
  final String name;
  final int hp;
  final int speed;
  final IconData abilityIcon;
  final String abilityName;
  final String portraitAsset;
  final String lockedPortraitAsset;
  final int unlockCost;
}

/// Character select — swipeable portrait carousel with live stats and Select CTA.
class CharacterSelectScreen extends StatefulWidget {
  const CharacterSelectScreen({super.key});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  static const List<GameCharacter> _characters = [
    GameCharacter(
      id: 'wanderer',
      name: 'Wanderer',
      hp: 120,
      speed: 8,
      abilityIcon: Icons.shield_moon_outlined,
      abilityName: 'Warding Veil',
      portraitAsset: AppAssets.charWanderer,
      lockedPortraitAsset: AppAssets.charWandererLocked,
    ),
    GameCharacter(
      id: 'huntress',
      name: 'Huntress',
      hp: 85,
      speed: 14,
      abilityIcon: Icons.visibility_outlined,
      abilityName: 'Night Sight',
      portraitAsset: AppAssets.charHuntress,
      lockedPortraitAsset: AppAssets.charHuntressLocked,
    ),
    GameCharacter(
      id: 'scholar',
      name: 'Scholar',
      unlockCost: 450,
      hp: 95,
      speed: 11,
      abilityIcon: Icons.auto_awesome,
      abilityName: 'Cinder Burst',
      portraitAsset: AppAssets.charScholar,
      lockedPortraitAsset: AppAssets.charScholarLocked,
    ),
    GameCharacter(
      id: 'brute',
      name: 'Brute',
      unlockCost: 700,
      hp: 140,
      speed: 6,
      abilityIcon: Icons.hardware_outlined,
      abilityName: 'Soul Tether',
      portraitAsset: AppAssets.charBrute,
      lockedPortraitAsset: AppAssets.charBruteLocked,
    ),
    GameCharacter(
      id: 'ghost',
      name: 'Ghost',
      unlockCost: 950,
      hp: 110,
      speed: 12,
      abilityIcon: Icons.flash_on_outlined,
      abilityName: 'Rift Slash',
      portraitAsset: AppAssets.charGhost,
      lockedPortraitAsset: AppAssets.charGhostLocked,
    ),
  ];

  late final PageController _pageController;
  double _page = 0;

  /// Stage chosen on the level grid (defaults to next playable).
  int? _pickedStageLevel;

  GameCharacter get _selected =>
      _characters[_page.round().clamp(0, _characters.length - 1)];

  int _stageFor(EconomyState economy, GameCharacter character) {
    final next = economy.nextPlayableLevel(character.id);
    final picked = _pickedStageLevel;
    if (picked != null &&
        economy.isStageUnlocked(character.id, picked) &&
        economy.ownsCharacter(character.id)) {
      return picked;
    }
    return next;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.62);
    _pageController.addListener(() {
      final page = _pageController.page ?? 0;
      if (page != _page) {
        setState(() {
          _page = page;
          _pickedStageLevel = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyState>();
    final selected = _selected;
    final canSelect = economy.ownsCharacter(selected.id);
    final stageLevel = _stageFor(economy, selected);

    return Scaffold(
      backgroundColor: _charcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: _maroon),
        title: Text(
          'Characters',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 20,
            letterSpacing: 3,
            color: Colors.white.withValues(alpha: 0.85),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: PageView.builder(
                controller: _pageController,
                itemCount: _characters.length,
                itemBuilder: (context, index) {
                  final distance = (_page - index).abs();
                  final t = (1 - distance).clamp(0.0, 1.0);
                  final scale = 0.9 + (0.2 * t); // ~0.9 → 1.1
                  final opacity = 0.5 + (0.5 * t);
                  final isFocused = distance < 0.5;
                  final character = _characters[index];

                  // Show Level-30 free-unlock messaging when prior char hit 30
                  // (whether still locked briefly, or already granted ownership).
                  final prevId = economy.previousCharacterId(character.id);
                  final priorMaxed = prevId != null &&
                      economy.bestLevelFor(prevId) >=
                          EconomyState.maxCharacterLevel;
                  final showLevelUnlockBadge = priorMaxed &&
                      (economy.canUnlockViaProgression(character.id) ||
                          (economy.ownsCharacter(character.id) &&
                              character.unlockCost > 0));

                  return Transform.scale(
                    scale: scale,
                    child: Opacity(
                      opacity: opacity,
                      child: _CharacterCard(
                        character: character,
                        locked: !economy.ownsCharacter(character.id),
                        focused: isFocused,
                        unlockedViaLevel: showLevelUnlockBadge,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: SingleChildScrollView(
                  key: ValueKey(selected.name),
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _StatsPanel(
                    character: selected,
                    clearedLevel: economy.bestLevelFor(selected.id),
                    selectedLevel: stageLevel,
                    canInteract: canSelect,
                    onLevelSelected: (level) {
                      if (!economy.isStageUnlocked(selected.id, level)) {
                        return;
                      }
                      setState(() => _pickedStageLevel = level);
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 20),
              child: _SelectButton(
                enabled: canSelect,
                label: canSelect
                    ? 'Play Level $stageLevel'
                    : 'Select',
                onPressed: canSelect
                    ? () {
                        economy.equipCharacter(selected.id);
                        final level = _stageFor(economy, selected);
                        Navigator.of(context).push(
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    PreGameSetupScreen(stageLevel: level),
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
                            transitionDuration:
                                const Duration(milliseconds: 450),
                          ),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CharacterCard extends StatefulWidget {
  const _CharacterCard({
    required this.character,
    required this.locked,
    required this.focused,
    this.unlockedViaLevel = false,
  });

  final GameCharacter character;
  final bool locked;
  final bool focused;
  final bool unlockedViaLevel;

  @override
  State<_CharacterCard> createState() => _CharacterCardState();
}

class _CharacterCardState extends State<_CharacterCard>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _glowPulse;
  late final Animation<double> _breath;

  @override
  void initState() {
    super.initState();
    _glowPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _breath = CurvedAnimation(parent: _glowPulse, curve: Curves.easeInOut);
    if (widget.focused) {
      _glowPulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _CharacterCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.focused && !oldWidget.focused) {
      _glowPulse.repeat(reverse: true);
    } else if (!widget.focused && oldWidget.focused) {
      _glowPulse
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _glowPulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final character = widget.character;
    final locked = widget.locked;
    final focused = widget.focused;
    final viaLevel = widget.unlockedViaLevel;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardW = constraints.maxWidth.clamp(0.0, 200.0);
        final cardH = constraints.maxHeight.clamp(0.0, 220.0);
        return Center(
          child: AnimatedBuilder(
            animation: _breath,
            builder: (context, child) {
              final pulse = focused ? _breath.value : 0.0;
              final borderColor = focused
                  ? Color.lerp(
                      _maroon.withValues(alpha: 0.75),
                      _maroonGlow,
                      0.35 + pulse * 0.65,
                    )!
                  : Colors.white.withValues(alpha: 0.12);
              return Container(
                width: cardW,
                height: cardH,
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: borderColor,
                    width: focused ? 2 : 1,
                  ),
                  boxShadow: focused
                      ? [
                          BoxShadow(
                            color: _maroonGlow.withValues(
                              alpha: 0.28 + pulse * 0.32,
                            ),
                            blurRadius: 16 + pulse * 14,
                            spreadRadius: 0.5 + pulse * 1.5,
                          ),
                          BoxShadow(
                            color:
                                _maroon.withValues(alpha: 0.2 + pulse * 0.12),
                            blurRadius: 36,
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
            child: Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          locked
                              ? character.lockedPortraitAsset
                              : character.portraitAsset,
                          fit: BoxFit.cover,
                        ),
                        if (locked)
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.45),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  AppAssets.iconLock,
                                  width: 28,
                                  height: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  viaLevel
                                      ? 'Unlocked via Level 30!'
                                      : '${character.unlockCost} Embers',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontFamily: 'serif',
                                    fontSize: viaLevel ? 10 : 12,
                                    letterSpacing: 1,
                                    color: viaLevel
                                        ? _maroonGlow.withValues(alpha: 0.95)
                                        : Colors.white.withValues(alpha: 0.75),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  character.name,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    letterSpacing: 1.5,
                    color: focused
                        ? Colors.white.withValues(alpha: 0.92)
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  locked
                      ? (viaLevel ? 'Unlocked via Level 30!' : 'Locked')
                      : (viaLevel ? 'Unlocked via Level 30!' : 'Unlocked'),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    letterSpacing: 1.2,
                    color: locked && !viaLevel
                        ? Colors.white.withValues(alpha: 0.35)
                        : _maroonGlow.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatsPanel extends StatelessWidget {
  const _StatsPanel({
    required this.character,
    required this.clearedLevel,
    required this.selectedLevel,
    required this.canInteract,
    required this.onLevelSelected,
  });

  final GameCharacter character;
  final int clearedLevel;
  final int selectedLevel;
  final bool canInteract;
  final ValueChanged<int> onLevelSelected;

  static const Color _maroon = Color(0xFF8B1A1A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'HP',
                    value: '${character.hp}',
                  ),
                ),
                _Divider(),
                Expanded(
                  child: _StatCell(
                    label: 'Speed',
                    value: '${character.speed}',
                  ),
                ),
                _Divider(),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ability',
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 10,
                          letterSpacing: 1.2,
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Icon(
                        character.abilityIcon,
                        size: 22,
                        color: _maroon,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        character.abilityName,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'serif',
                          fontSize: 11,
                          letterSpacing: 0.5,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Levels  ·  Cleared $clearedLevel/${EconomyState.maxCharacterLevel}'
                '  ·  Play $selectedLevel (${stageDurationLabel(selectedLevel)})',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 11,
                  letterSpacing: 1,
                  color: Colors.white.withValues(alpha: 0.55),
                ),
              ),
            ),
            const SizedBox(height: 8),
            _LevelCirclesGrid(
              clearedLevel: clearedLevel,
              selectedLevel: selectedLevel,
              canInteract: canInteract,
              onLevelSelected: onLevelSelected,
            ),
          ],
        ),
      ),
    );
  }
}

/// Circular level slots — cleared + next playable unlocked; tap to choose.
class _LevelCirclesGrid extends StatelessWidget {
  const _LevelCirclesGrid({
    required this.clearedLevel,
    required this.selectedLevel,
    required this.canInteract,
    required this.onLevelSelected,
  });

  final int clearedLevel;
  final int selectedLevel;
  final bool canInteract;
  final ValueChanged<int> onLevelSelected;

  static const Color _maroonGlow = Color(0xFFC41E1E);
  static const double _size = 30;

  @override
  Widget build(BuildContext context) {
    final max = EconomyState.maxCharacterLevel;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (var level = 1; level <= max; level++)
          _LevelCircle(
            level: level,
            unlocked: level <= clearedLevel + 1,
            cleared: level <= clearedLevel,
            current: level == selectedLevel,
            size: _size,
            accent: _maroonGlow,
            onTap: canInteract && level <= clearedLevel + 1
                ? () => onLevelSelected(level)
                : null,
          ),
      ],
    );
  }
}

class _LevelCircle extends StatelessWidget {
  const _LevelCircle({
    required this.level,
    required this.unlocked,
    required this.cleared,
    required this.current,
    required this.size,
    required this.accent,
    this.onTap,
  });

  final int level;
  final bool unlocked;
  final bool cleared;
  final bool current;
  final double size;
  final Color accent;
  final VoidCallback? onTap;

  static const Color _lockRing = Color(0xFF2A1818);

  @override
  Widget build(BuildContext context) {
    final lockColor = accent;
    final borderColor = current
        ? const Color(0xFFE8D5D5)
        : unlocked
            ? accent.withValues(alpha: cleared ? 0.55 : 0.85)
            : _lockRing;
    final fill = unlocked ? const Color(0xFF1A1212) : Colors.black;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: fill,
          border: Border.all(
            color: borderColor,
            width: current ? 2.4 : 1.4,
          ),
          boxShadow: [
            if (current)
              BoxShadow(
                color: accent.withValues(alpha: 0.45),
                blurRadius: 8,
              ),
            if (!unlocked)
              BoxShadow(
                color: lockColor.withValues(alpha: 0.28),
                blurRadius: 6,
              ),
          ],
        ),
        child: unlocked
            ? Center(
                child: Text(
                  '$level',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: current
                        ? Colors.white.withValues(alpha: 0.95)
                        : Colors.white.withValues(
                            alpha: cleared ? 0.55 : 0.8,
                          ),
                  ),
                ),
              )
            : Center(
                child: Icon(
                  Icons.lock,
                  size: 13,
                  color: lockColor,
                  shadows: [
                    Shadow(
                      color: lockColor.withValues(alpha: 0.85),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: lockColor.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 10,
            letterSpacing: 1.2,
            color: Colors.white.withValues(alpha: 0.4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 22,
            letterSpacing: 1,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: Colors.white.withValues(alpha: 0.08),
    );
  }
}

class _SelectButton extends StatelessWidget {
  const _SelectButton({
    required this.enabled,
    required this.onPressed,
    this.label = 'Select',
  });

  final bool enabled;
  final VoidCallback? onPressed;
  final String label;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed == null
              ? null
              : () {
                  AudioManager.instance.playTap();
                  onPressed!();
                },
          borderRadius: BorderRadius.circular(4),
          child: Ink(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              color: enabled
                  ? Colors.black.withValues(alpha: 0.5)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: enabled
                    ? _maroonGlow
                    : Colors.white.withValues(alpha: 0.15),
                width: enabled ? 1.6 : 1,
              ),
              boxShadow: enabled
                  ? [
                      BoxShadow(
                        color: _maroonGlow.withValues(alpha: 0.4),
                        blurRadius: 16,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 16,
                  letterSpacing: 2,
                  color: enabled
                      ? Colors.white.withValues(alpha: 0.92)
                      : Colors.white.withValues(alpha: 0.35),
                  shadows: enabled
                      ? [
                          Shadow(
                            color: _maroon.withValues(alpha: 0.6),
                            blurRadius: 8,
                          ),
                        ]
                      : null,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
