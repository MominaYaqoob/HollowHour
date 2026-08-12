import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../audio/audio_manager.dart';
import '../game/rune_catalog.dart';
import '../game/weapon_catalog.dart';
import '../state/economy_state.dart';
import '../theme/app_assets.dart';
import '../theme/themed_chrome.dart';

enum ShopCategory { characters, weapons, runes }

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    required this.owned,
    this.icon,
    this.imageAsset,
    this.ownedImageAsset,
    this.statLabel,
    this.statCurrent,
    this.statUpgrade,
    this.equipped = false,
  });

  final String id;
  final String name;
  final ShopCategory category;
  final IconData? icon;
  final String? imageAsset;
  final String? ownedImageAsset;
  final String description;
  final int price;
  final bool owned;
  final String? statLabel;
  final String? statCurrent;
  final String? statUpgrade;
  final bool equipped;

  String? get displayImage {
    if (owned) return ownedImageAsset ?? imageAsset;
    return imageAsset;
  }

  ShopItem copyWith({bool? owned, bool? equipped}) {
    return ShopItem(
      id: id,
      name: name,
      category: category,
      icon: icon,
      imageAsset: imageAsset,
      ownedImageAsset: ownedImageAsset,
      description: description,
      price: price,
      owned: owned ?? this.owned,
      statLabel: statLabel,
      statCurrent: statCurrent,
      statUpgrade: statUpgrade,
      equipped: equipped ?? this.equipped,
    );
  }
}

/// Shop / upgrades — tabbed catalog with purchase & equip bottom sheet.
class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const Color _charcoal = Color(0xFF0A0A0A);

  ShopCategory _category = ShopCategory.characters;

  static final List<ShopItem> _catalog = [
    ShopItem(
      id: 'wanderer',
      name: 'Wanderer',
      category: ShopCategory.characters,
      imageAsset: AppAssets.charWanderer,
      ownedImageAsset: AppAssets.charWanderer,
      description: 'Starting survivor. Balanced HP and speed.',
      price: 0,
      owned: false,
      statLabel: 'Role',
      statCurrent: 'Starter',
      statUpgrade: 'Balanced',
    ),
    ShopItem(
      id: 'huntress',
      name: 'Huntress',
      category: ShopCategory.characters,
      imageAsset: AppAssets.charHuntressLocked,
      ownedImageAsset: AppAssets.charHuntress,
      description: 'Faster scout. Lower HP, higher speed.',
      price: 21000,
      owned: false,
      statLabel: 'Speed',
      statCurrent: 'High',
      statUpgrade: '14',
    ),
    ShopItem(
      id: 'scholar',
      name: 'Scholar',
      category: ShopCategory.characters,
      imageAsset: AppAssets.charScholarLocked,
      ownedImageAsset: AppAssets.charScholar,
      description: 'Mystic fighter. Mid HP and speed.',
      price: 25000,
      owned: false,
      statLabel: 'Power',
      statCurrent: '—',
      statUpgrade: 'Burst',
    ),
    ShopItem(
      id: 'brute',
      name: 'Brute',
      category: ShopCategory.characters,
      imageAsset: AppAssets.charBruteLocked,
      ownedImageAsset: AppAssets.charBrute,
      description: 'Tanky brawler. Highest HP, slower move.',
      price: 32000,
      owned: false,
      statLabel: 'HP',
      statCurrent: '—',
      statUpgrade: '140',
    ),
    ShopItem(
      id: 'ghost',
      name: 'Ghost',
      category: ShopCategory.characters,
      imageAsset: AppAssets.charGhostLocked,
      ownedImageAsset: AppAssets.charGhost,
      description: 'Elusive striker. Strong speed, mid HP.',
      price: 40000,
      owned: false,
      statLabel: 'Speed',
      statCurrent: '—',
      statUpgrade: '12',
    ),
    ShopItem(
      id: 'blade',
      name: 'Rust Blade',
      category: ShopCategory.weapons,
      imageAsset: AppAssets.iconEmbers,
      description: WeaponCatalog.byId['blade']!.shopDescription,
      price: 0,
      owned: false,
      statLabel: 'Damage',
      statCurrent: '+35%',
      statUpgrade: 'Slow fire',
    ),
    ShopItem(
      id: 'pistol',
      name: 'Ember Pistol',
      category: ShopCategory.weapons,
      imageAsset: AppAssets.iconEmbers,
      description: WeaponCatalog.byId['pistol']!.shopDescription,
      price: 0,
      owned: false,
      statLabel: 'Damage',
      statCurrent: 'Base',
      statUpgrade: 'Balanced',
    ),
    ShopItem(
      id: 'axe',
      name: 'Grave Axe',
      category: ShopCategory.weapons,
      imageAsset: AppAssets.iconLock,
      description: WeaponCatalog.byId['axe']!.shopDescription,
      price: 21000,
      owned: false,
      statLabel: 'Damage',
      statCurrent: '+55%',
      statUpgrade: 'Wide hits',
    ),
    ShopItem(
      id: 'staff',
      name: 'Void Staff',
      category: ShopCategory.weapons,
      imageAsset: AppAssets.iconLock,
      description: WeaponCatalog.byId['staff']!.shopDescription,
      price: 24000,
      owned: false,
      statLabel: 'Fire rate',
      statCurrent: 'Fast',
      statUpgrade: '+range',
    ),
    ShopItem(
      id: 'bow',
      name: 'Hollow Bow',
      category: ShopCategory.weapons,
      imageAsset: AppAssets.iconLock,
      description: WeaponCatalog.byId['bow']!.shopDescription,
      price: 28000,
      owned: false,
      statLabel: 'Range',
      statCurrent: 'Long',
      statUpgrade: '+15% dmg',
    ),
    ShopItem(
      id: 'vein',
      name: 'Vein Rune',
      category: ShopCategory.runes,
      imageAsset: AppAssets.iconHp,
      description: RuneCatalog.byId['vein']!.shopDescription,
      price: 21000,
      owned: false,
      statLabel: 'HP',
      statCurrent: '+18',
      statUpgrade: 'Max HP',
    ),
    ShopItem(
      id: 'gale',
      name: 'Gale Rune',
      category: ShopCategory.runes,
      imageAsset: AppAssets.iconEmbers,
      description: RuneCatalog.byId['gale']!.shopDescription,
      price: 22000,
      owned: false,
      statLabel: 'Speed',
      statCurrent: '+18',
      statUpgrade: 'Move',
    ),
  ];

  ShopItem _resolve(ShopItem item, EconomyState economy) {
    final owned = switch (item.category) {
      ShopCategory.characters => economy.ownsCharacter(item.id),
      ShopCategory.weapons => economy.ownsWeapon(item.id),
      ShopCategory.runes => economy.ownsRune(item.id),
    };
    final equipped = switch (item.category) {
      ShopCategory.characters => economy.equippedCharacterId == item.id,
      ShopCategory.weapons => economy.equippedWeaponId == item.id,
      ShopCategory.runes => economy.equippedRuneIds.contains(item.id),
    };
    return item.copyWith(owned: owned, equipped: equipped);
  }

  List<ShopItem> _filtered(EconomyState economy) => _catalog
      .where((item) => item.category == _category)
      .map((item) => _resolve(item, economy))
      .toList();

  void _openItem(ShopItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Consumer<EconomyState>(
          builder: (context, economy, _) {
            final live = _resolve(item, economy);
            return _ItemDetailSheet(
              item: live,
              embers: economy.embers,
              onPurchase: () => _purchase(live),
              onEquip: () => _equip(live),
            );
          },
        );
      },
    );
  }

  void _purchase(ShopItem item) {
    final economy = context.read<EconomyState>();
    final ok = switch (item.category) {
      ShopCategory.characters =>
        economy.purchaseCharacter(item.id, item.price),
      ShopCategory.weapons => economy.purchaseWeapon(item.id, item.price),
      ShopCategory.runes => economy.purchaseRune(item.id, item.price),
    };
    if (!ok) return;
    AudioManager.instance.playPurchase();
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          '${item.name} purchased',
          style: const TextStyle(fontFamily: 'serif', letterSpacing: 0.5),
        ),
      ),
    );
  }

  void _equip(ShopItem item) {
    final economy = context.read<EconomyState>();
    switch (item.category) {
      case ShopCategory.characters:
        economy.equipCharacter(item.id);
      case ShopCategory.weapons:
        economy.equipWeapon(item.id);
      case ShopCategory.runes:
        economy.equipRune(item.id);
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: const Color(0xFF1A1A1A),
        content: Text(
          '${item.name} equipped',
          style: const TextStyle(fontFamily: 'serif', letterSpacing: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final economy = context.watch<EconomyState>();
    final items = _filtered(economy);

    return Scaffold(
      backgroundColor: _charcoal,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 16, 8),
              child: Row(
                children: [
                  ThemedBackButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const ThemedUiIcon(AppAssets.iconShop, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Shop',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  EmberBalanceChip(amount: economy.embers),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _CategoryTabs(
                value: _category,
                onChanged: (category) => setState(() => _category = category),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.92,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ShopCard(
                    item: item,
                    onTap: () => _openItem(item),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({
    required this.value,
    required this.onChanged,
  });

  final ShopCategory value;
  final ValueChanged<ShopCategory> onChanged;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

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
          for (final category in ShopCategory.values)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(category),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: value == category
                        ? _maroon.withValues(alpha: 0.35)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: value == category
                        ? [
                            BoxShadow(
                              color: _maroonGlow.withValues(alpha: 0.22),
                              blurRadius: 10,
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    switch (category) {
                      ShopCategory.characters => 'Characters',
                      ShopCategory.weapons => 'Weapons',
                      ShopCategory.runes => 'Runes',
                    },
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 12,
                      letterSpacing: 0.8,
                      color: value == category
                          ? Colors.white.withValues(alpha: 0.95)
                          : Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatefulWidget {
  const _ShopCard({
    required this.item,
    required this.onTap,
  });

  final ShopItem item;
  final VoidCallback onTap;

  @override
  State<_ShopCard> createState() => _ShopCardState();
}

class _ShopCardState extends State<_ShopCard>
    with SingleTickerProviderStateMixin {
  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  late final AnimationController _press;
  late final Animation<double> _scale;
  late final Animation<double> _glow;

  @override
  void initState() {
    super.initState();
    _press = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 240),
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.94), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.94, end: 1.0), weight: 1.2),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeOut));
    _glow = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 1.4),
    ]).animate(CurvedAnimation(parent: _press, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _press.dispose();
    super.dispose();
  }

  Future<void> _handleTap() async {
    await _press.forward(from: 0);
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final locked = !item.owned;

    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: _press,
        builder: (context, child) {
          final glow = _glow.value;
          return Transform.scale(
            scale: _scale.value,
            child: Opacity(
              opacity: locked ? 0.55 : 1,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF121212),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Color.lerp(
                      item.equipped
                          ? _maroonGlow.withValues(alpha: 0.7)
                          : Colors.white.withValues(alpha: 0.1),
                      _maroonGlow,
                      glow * 0.85,
                    )!,
                  ),
                  boxShadow: [
                    if (item.equipped || glow > 0.05)
                      BoxShadow(
                        color: _maroonGlow.withValues(
                          alpha: (item.equipped ? 0.2 : 0.0) + glow * 0.45,
                        ),
                        blurRadius: 12 + glow * 16,
                        spreadRadius: glow * 1.2,
                      ),
                  ],
                ),
                child: child,
              ),
            ),
          );
        },
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _maroon.withValues(alpha: 0.35),
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: item.displayImage != null
                        ? Image.asset(
                            item.displayImage!,
                            fit: item.category == ShopCategory.characters
                                ? BoxFit.cover
                                : BoxFit.contain,
                          )
                        : Icon(
                            item.icon ?? Icons.help_outline,
                            size: 36,
                            color: locked
                                ? Colors.white38
                                : _maroonGlow.withValues(alpha: 0.85),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 13,
                    letterSpacing: 0.8,
                    color: Colors.white.withValues(alpha: 0.88),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locked
                      ? '${item.price} Embers'
                      : item.equipped
                          ? 'Equipped'
                          : 'Owned',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 11,
                    letterSpacing: 0.6,
                    color: locked
                        ? Colors.white.withValues(alpha: 0.45)
                        : item.equipped
                            ? _maroonGlow
                            : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
            if (locked)
              Positioned(
                top: 4,
                right: 4,
                child: Container(
                  width: 20,
                  height: 20,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Image.asset(AppAssets.iconLock, fit: BoxFit.contain),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ItemDetailSheet extends StatelessWidget {
  const _ItemDetailSheet({
    required this.item,
    required this.embers,
    required this.onPurchase,
    required this.onEquip,
  });

  final ShopItem item;
  final int embers;
  final VoidCallback onPurchase;
  final VoidCallback onEquip;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final canAfford = embers >= item.price;
    final actionLabel = item.owned
        ? (item.equipped ? 'Equipped' : 'Equip')
        : 'Purchase';
    final actionEnabled =
        item.owned ? !item.equipped : canAfford;
    final action = item.owned ? onEquip : onPurchase;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.fromLTRB(
        20,
        16,
        20,
        16 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF121010),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _maroon.withValues(alpha: 0.55)),
        boxShadow: [
          BoxShadow(
            color: _maroonGlow.withValues(alpha: 0.2),
            blurRadius: 24,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _maroonGlow.withValues(alpha: 0.55)),
              boxShadow: [
                BoxShadow(
                  color: _maroonGlow.withValues(alpha: 0.25),
                  blurRadius: 16,
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: item.displayImage != null
                ? Image.asset(
                    item.displayImage!,
                    fit: item.category == ShopCategory.characters
                        ? BoxFit.cover
                        : BoxFit.contain,
                  )
                : Icon(
                    item.icon ?? Icons.help_outline,
                    size: 44,
                    color: _maroonGlow,
                  ),
          ),
          const SizedBox(height: 16),
          Text(
            item.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 22,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          if (item.statLabel != null) ...[
            const SizedBox(height: 18),
            _StatComparison(
              label: item.statLabel!,
              current: item.statCurrent ?? '—',
              upgrade: item.statUpgrade ?? '—',
              owned: item.owned,
            ),
          ],
          if (!item.owned) ...[
            const SizedBox(height: 12),
            Text(
              canAfford
                  ? 'Cost: ${item.price} Embers'
                  : 'Need ${item.price - embers} more Embers',
              style: TextStyle(
                fontFamily: 'serif',
                fontSize: 12,
                letterSpacing: 0.8,
                color: canAfford
                    ? Colors.white.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _SheetActionButton(
            label: actionLabel,
            enabled: actionEnabled,
            onTap: actionEnabled ? action : null,
          ),
        ],
      ),
    );
  }
}

class _StatComparison extends StatelessWidget {
  const _StatComparison({
    required this.label,
    required this.current,
    required this.upgrade,
    required this.owned,
  });

  final String label;
  final String current;
  final String upgrade;
  final bool owned;

  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Current',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                Text(
                  current,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward,
            size: 18,
            color: _maroonGlow.withValues(alpha: 0.7),
          ),
          Expanded(
            child: Column(
              children: [
                Text(
                  owned ? 'Equipped' : 'After',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    letterSpacing: 1,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  owned ? 'Value' : 'Upgrade',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                Text(
                  upgrade,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 16,
                    color: _maroonGlow.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatefulWidget {
  const _SheetActionButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_SheetActionButton> createState() => _SheetActionButtonState();
}

class _SheetActionButtonState extends State<_SheetActionButton>
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
      duration: const Duration(milliseconds: 280),
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
    if (widget.onTap == null) return;
    await _controller.forward(from: 0);
    if (!mounted) return;
    widget.onTap!();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.45,
      child: GestureDetector(
        onTap: widget.enabled ? _handleTap : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final glow = widget.enabled ? _glow.value : 0.25;
            return Transform.scale(
              scale: widget.enabled ? _scale.value : 1,
              child: Container(
                width: double.infinity,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.enabled
                        ? Color.lerp(_maroon, _maroonGlow, glow)!
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.6,
                  ),
                  boxShadow: widget.enabled
                      ? [
                          BoxShadow(
                            color: _maroonGlow.withValues(alpha: 0.35 * glow),
                            blurRadius: 16 * glow,
                            spreadRadius: 0.8 * glow,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 16,
                    letterSpacing: 3,
                    color: Colors.white.withValues(
                      alpha: widget.enabled ? 0.92 : 0.4,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
