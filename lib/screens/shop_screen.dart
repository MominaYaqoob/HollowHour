import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

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
  const ShopScreen({super.key, this.startingEmbers = 240});

  final int startingEmbers;

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  late int _embers;
  ShopCategory _category = ShopCategory.characters;

  late List<ShopItem> _items;

  @override
  void initState() {
    super.initState();
    _embers = widget.startingEmbers;
    _items = [
      const ShopItem(
        id: 'scholar',
        name: 'Scholar',
        category: ShopCategory.characters,
        imageAsset: AppAssets.charScholarLocked,
        ownedImageAsset: AppAssets.charScholar,
        description:
            'A cinder-touched mystic. Strong burst damage at the cost of frailty.',
        price: 450,
        owned: false,
        statLabel: 'Power',
        statCurrent: '—',
        statUpgrade: 'High',
      ),
      const ShopItem(
        id: 'wanderer',
        name: 'Wanderer',
        category: ShopCategory.characters,
        imageAsset: AppAssets.charWanderer,
        ownedImageAsset: AppAssets.charWanderer,
        description: 'Steadfast cloaked survivor of the dwindling light.',
        price: 0,
        owned: true,
        equipped: true,
        statLabel: 'Power',
        statCurrent: 'Balanced',
        statUpgrade: 'Balanced',
      ),
      const ShopItem(
        id: 'blade',
        name: 'Rust Blade',
        category: ShopCategory.weapons,
        imageAsset: AppAssets.iconEmbers,
        description: 'A notched blade that still remembers blood.',
        price: 0,
        owned: true,
        equipped: true,
        statLabel: 'Damage',
        statCurrent: '12',
        statUpgrade: '12',
      ),
      const ShopItem(
        id: 'axe',
        name: 'Grave Axe',
        category: ShopCategory.weapons,
        imageAsset: AppAssets.iconLock,
        description: 'Heavy swings that cleave the restless dead.',
        price: 320,
        owned: false,
        statLabel: 'Damage',
        statCurrent: '12',
        statUpgrade: '22',
      ),
      const ShopItem(
        id: 'vein',
        name: 'Vein Rune',
        category: ShopCategory.runes,
        imageAsset: AppAssets.iconHp,
        description: 'Permanently increases max vitality.',
        price: 180,
        owned: false,
        statLabel: 'HP',
        statCurrent: '120',
        statUpgrade: '145',
      ),
      const ShopItem(
        id: 'gale',
        name: 'Gale Rune',
        category: ShopCategory.runes,
        imageAsset: AppAssets.iconEmbers,
        description: 'Lightens your steps through choking fog.',
        price: 210,
        owned: true,
        equipped: false,
        statLabel: 'Speed',
        statCurrent: '8',
        statUpgrade: '11',
      ),
    ];
  }

  List<ShopItem> get _filtered =>
      _items.where((item) => item.category == _category).toList();

  void _openItem(ShopItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return _ItemDetailSheet(
          item: item,
          embers: _embers,
          onPurchase: () => _purchase(item),
          onEquip: () => _equip(item),
        );
      },
    );
  }

  void _purchase(ShopItem item) {
    if (item.owned || _embers < item.price) return;
    setState(() {
      _embers -= item.price;
      _items = _items
          .map((i) => i.id == item.id ? i.copyWith(owned: true) : i)
          .toList();
    });
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
    if (!item.owned) return;
    setState(() {
      _items = _items.map((i) {
        if (i.category != item.category) return i;
        if (i.id == item.id) return i.copyWith(equipped: true);
        return i.copyWith(equipped: false);
      }).toList();
    });
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back),
                    color: _maroon,
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(AppAssets.iconShop, width: 20, height: 20),
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
                    ],
                  ),
                  const Spacer(),
                  _EmberBalance(amount: _embers),
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
                itemCount: _filtered.length,
                itemBuilder: (context, index) {
                  final item = _filtered[index];
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

class _EmberBalance extends StatelessWidget {
  const _EmberBalance({required this.amount});

  final int amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(AppAssets.iconEmbers, width: 18, height: 18),
        const SizedBox(width: 6),
        Text(
          'Embers: $amount',
          style: TextStyle(
            fontFamily: 'serif',
            fontSize: 14,
            letterSpacing: 1.1,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
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

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.item,
    required this.onTap,
  });

  final ShopItem item;
  final VoidCallback onTap;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final locked = !item.owned;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: locked ? 0.55 : 1,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: item.equipped
                  ? _maroonGlow.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.1),
            ),
            boxShadow: item.equipped
                ? [
                    BoxShadow(
                      color: _maroonGlow.withValues(alpha: 0.2),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
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
