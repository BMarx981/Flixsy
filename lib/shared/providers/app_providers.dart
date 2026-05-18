import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/analytics_service.dart';
import '../../core/channels/android_tv_connect_channel.dart';
import '../../core/channels/composite_remote_channel.dart';
import '../../core/channels/multicast_lock.dart';
import '../../core/channels/remote_channel.dart';
import '../../core/channels/roku_connect_channel.dart';
import '../../core/channels/samsung_connect_channel.dart';
import '../../core/channels/webos_connect_channel.dart';
import '../../data/database/app_database.dart';
import '../../data/repositories/preferences_repository.dart';
import '../../domain/repositories/i_preferences_repository.dart';
import '../../router/app_router.dart';
import '../ads/ad_service.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final preferencesRepositoryProvider = Provider<IPreferencesRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PreferencesRepository(db);
});

/// Singleton router — never instantiate [AppRouter] more than once.
final appRouterProvider = Provider<AppRouter>((ref) => AppRouter());

/// Requires [Firebase.initializeApp()] to have completed before first access.
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(FirebaseAnalytics.instance);
});

final adServiceProvider = Provider<AdService>((ref) {
  final analytics = ref.watch(analyticsServiceProvider);
  return AdService(analytics);
});

/// App-wide [RemoteChannel] — the pure-Dart [CompositeRemoteChannel] fanning
/// across the per-vendor channels (Roku, webOS, Samsung, and Android TV).
/// Always obtain the channel through this provider; never instantiate one
/// elsewhere.
final connectChannelProvider = Provider<RemoteChannel>((ref) {
  final preferences = ref.watch(preferencesRepositoryProvider);
  final channel = CompositeRemoteChannel([
    RokuConnectChannel(),
    WebosConnectChannel(
      loadCredential: preferences.getDeviceCredential,
      saveCredential: preferences.setDeviceCredential,
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
