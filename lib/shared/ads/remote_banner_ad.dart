import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/app_providers.dart';

/// Renders a banner ad, or an empty [SizedBox] while it loads. Owns its own
/// [BannerAd] instance so multiple banners can coexist on different routes.
/// Screens embed this widget in their layout; skins do not control ad placement.
class RemoteBannerAd extends ConsumerStatefulWidget {
  const RemoteBannerAd({super.key});

  @override
  ConsumerState<RemoteBannerAd> createState() => _RemoteBannerAdState();
}

class _RemoteBannerAdState extends ConsumerState<RemoteBannerAd> {
  BannerAd? _ad;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  Future<void> _loadAd() async {
    final ad = await ref.read(adServiceProvider).createBannerAd(
      onLoaded: () {
        if (mounted) setState(() => _isLoaded = true);
      },
    );
    if (!mounted) {
      ad?.dispose();
      return;
    }
    setState(() => _ad = ad);
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_isLoaded || ad == null) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: ad.size.width.toDouble(),
      height: ad.size.height.toDouble(),
      child: AdWidget(ad: ad),
    );
  }
}
