import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:flixsy/analytics/analytics_service.dart';

/// Drives Google's User Messaging Platform (UMP) consent flow.
///
/// Wraps [ConsentInformation] and [ConsentForm] from `google_mobile_ads`'s
/// UMP helpers. AdMob policy requires this before loading ads in the EU /
/// regulated US states.
class ConsentService {
  ConsentService(this._analytics);

  final AnalyticsService _analytics;

  bool _hasResolved = false;

  /// True once the consent form (if any was required) has been resolved.
  bool get hasResolved => _hasResolved;

  /// Requests consent information and, if needed, shows the consent form.
  /// Safe to call once at app start.
  Future<void> requestConsent() async {
    final params = ConsentRequestParameters();
    final updateInfo = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      updateInfo.complete,
      (_) => updateInfo.complete(),
    );
    await updateInfo.future;

    final dismissed = Completer<void>();
    await ConsentForm.loadAndShowConsentFormIfRequired((_) {
      if (!dismissed.isCompleted) dismissed.complete();
    });
    if (!dismissed.isCompleted) dismissed.complete();
    await dismissed.future;

    _hasResolved = true;
    await _analytics.logConsentResolved(canRequestAds: await canRequestAds());
  }

  /// Whether AdMob may request ads given the current consent state.
  Future<bool> canRequestAds() =>
      ConsentInformation.instance.canRequestAds();
}
