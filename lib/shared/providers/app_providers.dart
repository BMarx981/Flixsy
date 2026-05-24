import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/core/channels/android_tv_connect_channel.dart';
import 'package:flixsy/core/channels/composite_remote_channel.dart';
import 'package:flixsy/core/channels/multicast_lock.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/core/channels/roku_connect_channel.dart';
import 'package:flixsy/core/channels/samsung_connect_channel.dart';
import 'package:flixsy/core/channels/webos_connect_channel.dart';
import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/repositories/custom_image_repository.dart';
import 'package:flixsy/data/repositories/layout_repository.dart';
import 'package:flixsy/data/repositories/preferences_repository.dart';
import 'package:flixsy/domain/repositories/i_custom_image_repository.dart';
import 'package:flixsy/domain/repositories/i_layout_repository.dart';
import 'package:flixsy/domain/repositories/i_preferences_repository.dart';
import 'package:flixsy/router/app_router.dart';
import 'package:flixsy/shared/ads/ad_service.dart';
import 'package:flixsy/shared/ads/consent_service.dart';
import 'package:flixsy/shared/iap/iap_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final preferencesRepositoryProvider = Provider<IPreferencesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PreferencesRepository(db);
});

final layoutRepositoryProvider = Provider<ILayoutRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return LayoutRepository(db);
});

final customImageRepositoryProvider = Provider<ICustomImageRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return CustomImageRepository(db);
});

/// Singleton router — never instantiate [AppRouter] more than once.
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

/// Requires [Firebase.initializeApp()] to have completed before first access.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});

final consentServiceProvider = Provider<ConsentService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return ConsentService(analytics);
});

final adServiceProvider = Provider<AdService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  final consent = ref.watch(consentServiceProvider);
  return AdService(analytics, consent);
});

/// Tracks whether the user has purchased the "Remove Ads" entitlement.
/// Streams updates so widgets re-render the moment the entitlement flips.
final adsRemovedProvider = StreamProvider<bool>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  return prefs.watchAdsRemoved();
});

/// Long-lived [IapService] singleton. Initialization (subscribing to the
/// platform purchase stream) is kicked off in `main.dart` after app start.
final iapServiceProvider = Provider<IapService>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final service = IapService(prefs, analytics);
  ref.onDispose(service.dispose);
  return service;
});

/// Localized [ProductDetails] (title + price) for the "Remove Ads" IAP, or
/// `null` if the store is unavailable / the product is not configured.
final removeAdsProductProvider = FutureProvider<ProductDetails?>((ref) async {
  final iap = ref.watch(iapServiceProvider);
  return iap.queryProducts();
});

/// App-wide [RemoteChannel] — the pure-Dart [CompositeRemoteChannel] fanning
/// across the per-vendor channels (Roku, webOS, Samsung, and Android TV).
/// Always obtain the channel through this provider; never instantiate one
/// elsewhere.
final remoteChannelProvider = Provider<RemoteChannel>((ref) {
  final preferences = ref.watch(preferencesRepositoryProvider);
  final channel = CompositeRemoteChannel([
    RokuConnectChannel(),
    WebosConnectChannel(
      loadCredential: preferences.getDeviceCredential,
      saveCredential: preferences.setDeviceCredential,
      loadMacAddress: preferences.getDeviceMacAddress,
      saveMacAddress: preferences.setDeviceMacAddress,
    ),
    SamsungConnectChannel(
      loadCredential: preferences.getDeviceCredential,
      saveCredential: preferences.setDeviceCredential,
    ),
    AndroidTvConnectChannel(
      loadCredential: preferences.getDeviceCredential,
      saveCredential: preferences.setDeviceCredential,
    ),
  ], multicastLock: PlatformMulticastLock());
  ref.onDispose(channel.dispose);
  return channel;
});
