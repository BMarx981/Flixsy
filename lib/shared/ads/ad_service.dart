import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../analytics/analytics_service.dart';

class AdService {
  AdService(this._analyticsService);

  final AnalyticsService _analyticsService;

  // Test ad unit IDs — replace via environment config in production.
  static final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;

  bool get isBannerAdLoaded => _isBannerAdLoaded;
  BannerAd? get bannerAd => _bannerAd;

  Future<void> loadBannerAd({required void Function() onLoaded}) async {
    _bannerAd = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          _isBannerAdLoaded = true;
          onLoaded();
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _bannerAd = null;
          _isBannerAdLoaded = false;
        },
        onAdImpression: (ad) {
          _analyticsService.logAdViewed(ad.adUnitId);
        },
      ),
    );
    await _bannerAd!.load();
  }

  void disposeBannerAd() {
    _bannerAd?.dispose();
    _bannerAd = null;
    _isBannerAdLoaded = false;
  }
}
