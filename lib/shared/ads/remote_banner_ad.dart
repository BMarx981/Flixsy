import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../providers/app_providers.dart';

/// Renders the loaded banner ad, or an empty [SizedBox] while it loads.
/// Screens embed this widget in their layout; skins do not control ad placement.
class RemoteBannerAd extends ConsumerStatefulWidget {
  const RemoteBannerAd({super.key});

  @override
  ConsumerState<RemoteBannerAd> createState() => _RemoteBannerAdState();
}

class _RemoteBannerAdState extends ConsumerState<RemoteBannerAd> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    ref.read(adServiceProvider).loadBannerAd(
          onLoaded: () {
            if (mounted) setState(() => _isLoaded = true);
          },
        );
  }

  @override
  void dispose() {
    ref.read(adServiceProvider).disposeBannerAd();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final adService = ref.watch(adServiceProvider);

    if (!_isLoaded || adService.bannerAd == null) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      width: adService.bannerAd!.size.width.toDouble(),
      height: adService.bannerAd!.size.height.toDouble(),
      child: AdWidget(ad: adService.bannerAd!),
    );
  }
}
