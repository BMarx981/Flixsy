import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../analytics/analytics_service.dart';
import '../../core/channels/connect_channel.dart';
import '../../core/channels/remote_channel.dart';
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

/// App-wide [RemoteChannel]. Phase 0 keeps the native [ConnectChannel] as the
/// implementation; Phase 3 replaces it with the pure-Dart
/// `CompositeRemoteChannel`. Always go through this provider — never
/// instantiate a channel elsewhere.
final connectChannelProvider = Provider<RemoteChannel>((ref) {
  return ConnectChannel();
});
