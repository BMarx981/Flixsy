import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/shared/ads/consent_service.dart';

class AdService {
  AdService(this._analyticsService, this._consentService);

  final AnalyticsService _analyticsService;
  final ConsentService _consentService;

  // Test ad unit IDs — replace via environment config in production.
  static final String _bannerAdUnitId = Platform.isAndroid
      ? 'ca-app-pub-3940256099942544/6300978111'
      : 'ca-app-pub-3940256099942544/2934735716';

  /// Creates and starts loading a fresh [BannerAd]. Each [RemoteBannerAd]
  /// widget owns its own instance so multiple banners can coexist (e.g. on
  /// separate routes still in the navigator stack).
  ///
  /// Returns `null` if UMP consent has not been granted yet — callers should
  /// render nothing in that case.
  Future<BannerAd?> createBannerAd({required void Function() onLoaded}) async {
    if (!await _consentService.canRequestAds()) return null;
    final ad = BannerAd(
      adUnitId: _bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) => onLoaded(),
        onAdFailedToLoad: (ad, _) => ad.dispose(),
        onAdImpression: (ad) {
          _analyticsService.logAdViewed(ad.adUnitId);
        },
      ),
    );
    await ad.load();
    return ad;
  }
}
