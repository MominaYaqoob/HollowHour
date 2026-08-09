import 'package:flutter/material.dart';

import '../theme/app_assets.dart';

class _TalentNode {
  _TalentNode({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.maxLevel,
    required this.baseValue,
    required this.perLevel,
    required this.unit,
    required this.baseCost,
    required this.requiresId,
    this.imageAsset,
    this.level = 0,
  });

  final String id;
  final String name;
  final IconData icon;
  final String? imageAsset;
  final String description;
  final int maxLevel;
  final double baseValue;
  final double perLevel;
  final String unit;
  final int baseCost;
  final String? requiresId;
  int level;

  bool get isMaxed => level >= maxLevel;
  int get nextCost => baseCost + (level * 40);
  String get currentLabel =>
      '${_fmt(baseValue + level * perLevel)}$unit';
  String get nextLabel => isMaxed
      ? 'MAX'
      : '${_fmt(baseValue + (level + 1) * perLevel)}$unit';

  static String _fmt(double v) {
    if (v == v.roundToDouble()) return '${v.round()}';
    return v.toStringAsFixed(1);
  }
}

/// Permanent talent upgrades mockup — local setState only.
class TalentTreeScreen extends StatefulWidget {
  const TalentTreeScreen({super.key, this.startingEmbers = 240});

  final int startingEmbers;

  @override
  State<TalentTreeScreen> createState() => _TalentTreeScreenState();
}

class _TalentTreeScreenState extends State<TalentTreeScreen> {
  static const Color _charcoal = Color(0xFF0A0A0A);
  static const Color _maroon = Color(0xFF8B1A1A);

  late int _embers;
  late List<_TalentNode> _nodes;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _embers = widget.startingEmbers;
    _nodes = [
      _TalentNode(
        id: 'vitality',
        name: 'Max HP',
        icon: Icons.favorite_border,
        imageAsset: AppAssets.iconHp,
        description: 'Permanently raise your maximum vitality.',
        maxLevel: 5,
        baseValue: 100,
        perLevel: 15,
        unit: ' HP',
        baseCost: 120,
        requiresId: null,
        level: 2,
      ),
      _TalentNode(
        id: 'ferocity',
        name: 'Damage',
        icon: Icons.flash_on_outlined,
        description: 'Sharpen every strike that leaves your hand.',
        maxLevel: 5,
        baseValue: 10,
        perLevel: 2,
        unit: ' DMG',
        baseCost: 90,
        requiresId: 'vitality',
        level: 1,
      ),
      _TalentNode(
        id: 'swiftness',
        name: 'Speed',
        icon: Icons.speed,
        description: 'Move more freely through choking fog.',
        maxLevel: 5,
        baseValue: 1.0,
        perLevel: 0.1,
        unit: 'x',
        baseCost: 85,
        requiresId: 'vitality',
        level: 0,
      ),
      _TalentNode(
        id: 'fortune',
        name: 'Luck',
        icon: Icons.auto_awesome,
        description: 'Draw more embers and XP from the Hollow.',
        maxLevel: 5,
        baseValue: 0,
        perLevel: 8,
        unit: '% XP',
        baseCost: 100,
        requiresId: 'ferocity',
        level: 0,
      ),
      _TalentNode(
        id: 'warding',
        name: 'Warding',
        icon: Icons.shield_moon_outlined,
        description: 'Reduce the sting of each wound taken.',
        maxLevel: 5,
        baseValue: 0,
        perLevel: 4,
        unit: '% DEF',
        baseCost: 95,
        requiresId: 'swiftness',
        level: 0,
      ),
      _TalentNode(
        id: 'emberheart',
        name: 'Emberheart',
        icon: Icons.local_fire_department_outlined,
        imageAsset: AppAssets.iconEmbers,
        description: 'A final spark — rare finds glow brighter.',
        maxLevel: 3,
        baseValue: 0,
        perLevel: 10,
        unit: '% LUCK',
        baseCost: 140,
        requiresId: 'fortune',
        level: 0,
      ),
    ];
  }

  _TalentNode? get _selected {
    if (_selectedId == null) return null;
    return _nodes.firstWhere((n) => n.id == _selectedId);
  }

  bool _isUnlocked(_TalentNode node) {
    if (node.requiresId == null) return true;
    final req = _nodes.firstWhere((n) => n.id == node.requiresId);
    return req.level > 0;
  }

  void _upgrade(_TalentNode node) {
    if (!_isUnlocked(node) || node.isMaxed) return;
    if (_embers < node.nextCost) return;
    setState(() {
      _embers -= node.nextCost;
      node.level += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Scaffold(
      backgroundColor: _charcoal,
      body: SafeArea(
        child: Column(
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
                  Text(
                    'Talents',
                    style: TextStyle(
                      fontFamily: 'serif',
                      fontSize: 18,
                      letterSpacing: 3,
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const Spacer(),
                  _EmberBalance(amount: _embers),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  children: [
                    Text(
                      'Marks that linger beyond a single hour.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'serif',
                        fontSize: 12,
                        letterSpacing: 0.8,
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      height: 520,
                      child: CustomPaint(
                        painter: _TreeLinesPainter(
                          unlocked: {
                            for (final n in _nodes) n.id: _isUnlocked(n) && n.level > 0,
                          },
                        ),
                        child: Stack(
                          children: [
                            // Tier 0 — root
                            Align(
                              alignment: const Alignment(0, -0.95),
                              child: _buildNodeChip('vitality'),
                            ),
                            // Tier 1
                            Align(
                              alignment: const Alignment(-0.7, -0.35),
                              child: _buildNodeChip('ferocity'),
                            ),
                            Align(
                              alignment: const Alignment(0.7, -0.35),
                              child: _buildNodeChip('swiftness'),
                            ),
                            // Tier 2
                            Align(
                              alignment: const Alignment(-0.7, 0.25),
                              child: _buildNodeChip('fortune'),
                            ),
                            Align(
                              alignment: const Alignment(0.7, 0.25),
                              child: _buildNodeChip('warding'),
                            ),
                            // Tier 3
                            Align(
                              alignment: const Alignment(0, 0.9),
                              child: _buildNodeChip('emberheart'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (selected != null) ...[
                      const SizedBox(height: 8),
                      _TalentDetailCard(
                        node: selected,
                        unlocked: _isUnlocked(selected),
                        canAfford: _embers >= selected.nextCost,
                        onUpgrade: () => _upgrade(selected),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNodeChip(String id) {
    final node = _nodes.firstWhere((n) => n.id == id);
    final unlocked = _isUnlocked(node);
    final selected = _selectedId == id;
    return _TalentNodeChip(
      node: node,
      unlocked: unlocked,
      selected: selected,
      onTap: () => setState(() => _selectedId = id),
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

class _TalentNodeChip extends StatelessWidget {
  const _TalentNodeChip({
    required this.node,
    required this.unlocked,
    required this.selected,
    required this.onTap,
  });

  final _TalentNode node;
  final bool unlocked;
  final bool selected;
  final VoidCallback onTap;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final active = unlocked && node.level > 0;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: unlocked ? 1 : 0.4,
        child: Container(
          width: 96,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF121212),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected
                  ? _maroonGlow
                  : active
                      ? _maroon.withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.12),
              width: selected ? 1.8 : 1.1,
            ),
            boxShadow: selected || active
                ? [
                    BoxShadow(
                      color: _maroonGlow.withValues(
                        alpha: selected ? 0.4 : 0.18,
                      ),
                      blurRadius: selected ? 14 : 8,
                    ),
                  ]
                : null,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (node.imageAsset != null)
                    Opacity(
                      opacity: unlocked ? 1 : 0.45,
                      child: Image.asset(
                        node.imageAsset!,
                        width: 26,
                        height: 26,
                      ),
                    )
                  else
                    Icon(
                      node.icon,
                      size: 26,
                      color: unlocked
                          ? _maroonGlow.withValues(alpha: 0.9)
                          : Colors.white38,
                    ),
                  if (!unlocked)
                    Image.asset(AppAssets.iconLock, width: 14, height: 14),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                node.name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 11,
                  letterSpacing: 0.6,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${node.level}/${node.maxLevel}',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
              ),
              if (!node.isMaxed && unlocked)
                Text(
                  '${node.nextCost}',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 10,
                    color: _maroonGlow.withValues(alpha: 0.75),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TalentDetailCard extends StatelessWidget {
  const _TalentDetailCard({
    required this.node,
    required this.unlocked,
    required this.canAfford,
    required this.onUpgrade,
  });

  final _TalentNode node;
  final bool unlocked;
  final bool canAfford;
  final VoidCallback onUpgrade;

  static const Color _maroon = Color(0xFF8B1A1A);
  static const Color _maroonGlow = Color(0xFFC41E1E);

  @override
  Widget build(BuildContext context) {
    final canUpgrade = unlocked && !node.isMaxed && canAfford;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _maroon.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            node.name,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 18,
              letterSpacing: 1.5,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            node.description,
            style: TextStyle(
              fontFamily: 'serif',
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                node.currentLabel,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.75),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  Icons.arrow_forward,
                  size: 14,
                  color: _maroonGlow.withValues(alpha: 0.7),
                ),
              ),
              Text(
                node.nextLabel,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                  color: _maroonGlow.withValues(alpha: 0.95),
                ),
              ),
              const Spacer(),
              if (!unlocked)
                Text(
                  'Locked',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                )
              else if (node.isMaxed)
                Text(
                  'Maxed',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 12,
                    color: _maroonGlow.withValues(alpha: 0.8),
                  ),
                )
              else
                Text(
                  'Cost: ${node.nextCost}',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 12,
                    color: canAfford
                        ? Colors.white.withValues(alpha: 0.55)
                        : Colors.white.withValues(alpha: 0.3),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          _UpgradeButton(
            enabled: canUpgrade,
            onTap: onUpgrade,
          ),
        ],
      ),
    );
  }
}

class _UpgradeButton extends StatefulWidget {
  const _UpgradeButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  State<_UpgradeButton> createState() => _UpgradeButtonState();
}

class _UpgradeButtonState extends State<_UpgradeButton>
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
        tween: Tween(begin: 0.94, end: 1.04)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 1.2,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.04, end: 1.0)
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
    if (!widget.enabled) return;
    await _controller.forward(from: 0);
    if (!mounted) return;
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: widget.enabled ? 1 : 0.4,
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
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                    color: widget.enabled
                        ? Color.lerp(_maroon, _maroonGlow, glow)!
                        : Colors.white.withValues(alpha: 0.18),
                    width: 1.5,
                  ),
                  boxShadow: widget.enabled
                      ? [
                          BoxShadow(
                            color: _maroonGlow.withValues(alpha: 0.3 * glow),
                            blurRadius: 14 * glow,
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  'Upgrade',
                  style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 15,
                    letterSpacing: 2.5,
                    color: Colors.white.withValues(
                      alpha: widget.enabled ? 0.9 : 0.4,
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

/// Draws simple connector lines between talent tiers.
class _TreeLinesPainter extends CustomPainter {
  _TreeLinesPainter({required this.unlocked});

  final Map<String, bool> unlocked;

  static const Color _dim = Color(0x33FFFFFF);
  static const Color _lit = Color(0x668B1A1A);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    Offset p(double x, double y) => Offset(size.width * x, size.height * y);

    void line(Offset a, Offset b, bool active) {
      paint.color = active ? _lit : _dim;
      canvas.drawLine(a, b, paint);
    }

    final root = p(0.5, 0.08);
    final left1 = p(0.2, 0.35);
    final right1 = p(0.8, 0.35);
    final left2 = p(0.2, 0.58);
    final right2 = p(0.8, 0.58);
    final tip = p(0.5, 0.88);

    line(root, left1, unlocked['ferocity'] == true);
    line(root, right1, unlocked['swiftness'] == true);
    line(left1, left2, unlocked['fortune'] == true);
    line(right1, right2, unlocked['warding'] == true);
    line(left2, tip, unlocked['emberheart'] == true);
    line(right2, tip, unlocked['emberheart'] == true);
  }

  @override
  bool shouldRepaint(covariant _TreeLinesPainter oldDelegate) =>
      oldDelegate.unlocked != unlocked;
}
