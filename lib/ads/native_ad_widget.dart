import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Template size for [NativeAdWidget] / Android factory layouts.
enum NativeAdFormat { small, medium }

/// Custom-styled AdMob native ad (factoryId: `hollow_native`).
///
/// Renders nothing until loaded — no placeholder gap.
class NativeAdWidget extends StatefulWidget {
  const NativeAdWidget({
    super.key,
    required this.adUnitId,
    required this.height,
    required this.format,
    this.ensureInitialized,
  });

  final String adUnitId;
  final double height;
  final NativeAdFormat format;
  final Future<void> Function()? ensureInitialized;

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  static const Color _border = Color(0x14FFFFFF); // white @ ~8%

  NativeAd? _nativeAd;
  bool _isLoaded = false;
  Brightness? _appliedBrightness;
  bool _loading = false;

  bool get _isMedium => widget.format == NativeAdFormat.medium;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final brightness = Theme.of(context).brightness;
    if (_appliedBrightness == null) {
      _appliedBrightness = brightness;
      _loadAd(brightness);
      return;
    }
    if (_appliedBrightness != brightness) {
      _appliedBrightness = brightness;
      _disposeAd();
      _loadAd(brightness);
    }
  }

  Future<void> _loadAd(Brightness brightness) async {
    if (_loading) return;
    _loading = true;
    try {
      final ensure = widget.ensureInitialized;
      if (ensure != null) {
        await ensure();
      }
      if (!mounted) return;

      final ad = NativeAd(
        adUnitId: widget.adUnitId,
        factoryId: 'hollow_native',
        request: const AdRequest(),
        customOptions: {
          'format': _isMedium ? 'medium' : 'small',
          'isDark': brightness == Brightness.dark,
        },
        listener: NativeAdListener(
          onAdLoaded: (ad) {
            if (!mounted) {
              ad.dispose();
              return;
            }
            setState(() {
              _nativeAd = ad as NativeAd;
              _isLoaded = true;
              _loading = false;
            });
          },
          onAdFailedToLoad: (ad, error) {
            debugPrint(
              'NativeAd failedToLoad: code=${error.code} '
              'domain=${error.domain} message=${error.message}',
            );
            ad.dispose();
            if (!mounted) return;
            setState(() {
              _nativeAd = null;
              _isLoaded = false;
              _loading = false;
            });
          },
        ),
      );
      await ad.load();
    } catch (e, st) {
      debugPrint('NativeAdWidget load exception: $e\n$st');
      if (mounted) {
        setState(() {
          _isLoaded = false;
          _loading = false;
        });
      } else {
        _loading = false;
      }
    }
  }

  void _disposeAd() {
    _nativeAd?.dispose();
    _nativeAd = null;
    _isLoaded = false;
    _loading = false;
  }

  @override
  void dispose() {
    _disposeAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
        color: isDark ? const Color(0xFF121010) : Colors.white,
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
