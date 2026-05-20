import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/data/models/stored_image.dart';
import 'package:flixsy/domain/repositories/i_custom_image_repository.dart';
import 'package:flixsy/domain/repositories/i_layout_repository.dart';
import 'package:flixsy/domain/repositories/i_preferences_repository.dart';
import 'package:flixsy/features/home/screens/home_screen.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/shared/ads/ad_service.dart';
import 'package:flixsy/shared/ads/consent_service.dart';
import 'package:flixsy/shared/ads/remote_banner_ad.dart';
import 'package:flixsy/shared/iap/iap_service.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/theming/skin_registry.dart';
import 'package:flixsy/theming/skins/main/main_remote_skin.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePreferencesRepository preferences;
  late _FakeAnalyticsService analytics;
  late _FakeRemoteChannel channel;
  late _FakeLayoutRepository layouts;

  setUp(() {
    preferences = _FakePreferencesRepository();
    analytics = _FakeAnalyticsService();
    channel = _FakeRemoteChannel();
    layouts = _FakeLayoutRepository();
  });

  tearDown(() {
    preferences.dispose();
    channel.dispose();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    final fakeConsent = _FakeConsentService(analytics);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(preferences),
          analyticsServiceProvider.overrideWithValue(analytics),
          remoteChannelProvider.overrideWithValue(channel),
          layoutRepositoryProvider.overrideWithValue(layouts),
          customImageRepositoryProvider.overrideWithValue(
            _FakeCustomImageRepository(),
          ),
          consentServiceProvider.overrideWithValue(fakeConsent),
          adServiceProvider.overrideWithValue(
            AdService(analytics, fakeConsent),
          ),
          iapServiceProvider.overrideWithValue(
            _FakeIapService(preferences, analytics),
          ),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: HomeScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the active skin — classic by default', (tester) async {
    await pumpHome(tester);

    // The classic skin is now a standard skin: StandardRemote + a renderer.
    expect(find.byType(StandardRemote), findsOneWidget);
    expect(find.byType(MainRemoteSkin), findsNothing);
  });

  testWidgets('skin picker previews and applies a new skin', (tester) async {
    await pumpHome(tester);

    // Enter selection mode — the picker carousel replaces the remote body.
    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();

    // Step forward to the Main skin via the chevron arrow.
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();

    // Preview only: nothing has been persisted yet.
    expect(analytics.skinsChanged, isEmpty);

    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    expect(find.byType(MainRemoteSkin), findsOneWidget);
    expect(find.byType(StandardRemote), findsNothing);
    expect(analytics.skinsChanged, contains('main'));
  });

  testWidgets('skin picker cancel reverts to the saved skin', (tester) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    // Cancel discards the preview — classic is still active and nothing logged.
    expect(find.byType(StandardRemote), findsOneWidget);
    expect(find.byType(MainRemoteSkin), findsNothing);
    expect(analytics.skinsChanged, isEmpty);
  });

  testWidgets('pressing a remote key sends the command and logs it', (
    tester,
  ) async {
    await pumpHome(tester);

    // The default classic skin renders a labelled 'OK' button.
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(channel.sentKeys, ['OK']);
    expect(analytics.keysSent, ['OK']);
  });

  testWidgets('renders the banner ad when ads have not been removed', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.byType(RemoteBannerAd), findsOneWidget);
  });

  testWidgets('hides the banner ad once ads have been removed', (tester) async {
    preferences._adsRemoved = true;
    await pumpHome(tester);
    expect(find.byType(RemoteBannerAd), findsNothing);
  });

  testWidgets('main skin control buttons route through the remote channel', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.chevron_right));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Apply'));
    await tester.pumpAndSettle();

    // The Back/Home/transport buttons added to the main skin must reach the
    // channel exactly like the directional keys do.
    await tester.tap(find.byIcon(Icons.home_outlined));
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pumpAndSettle();

    expect(channel.sentKeys, ['HOME', 'BACK']);
    expect(analytics.keysSent, ['HOME', 'BACK']);
  });
}

/// In-memory stand-in for the Drift-backed preferences repository.
///
/// A single-subscription [StreamController] buffers the initial skin until
/// the provider subscribes, then forwards every [setActiveSkin] change.
class _FakePreferencesRepository implements IPreferencesRepository {
  _FakePreferencesRepository() {
    _controller.add(_active);
    _layoutController.add(_activeLayoutId);
  }

  AppSkin _active = AppSkin.classic;
  final StreamController<AppSkin> _controller = StreamController<AppSkin>();
  String? _activeLayoutId;
  final StreamController<String?> _layoutController =
      StreamController<String?>();
  final Map<String, String> _credentials = {};

  @override
  Stream<AppSkin> watchActiveSkin() => _controller.stream;

  @override
  Future<AppSkin> getActiveSkin() async => _active;

  @override
  Future<void> setActiveSkin(AppSkin skin) async {
    _active = skin;
    _controller.add(skin);
  }

  @override
  Stream<String?> watchActiveLayoutId() => _layoutController.stream;

  @override
  Future<String?> getActiveLayoutId() async => _activeLayoutId;

  @override
  Future<void> setActiveLayoutId(String layoutId) async {
    _activeLayoutId = layoutId;
    _layoutController.add(layoutId);
  }

  bool _adsRemoved = false;
  final StreamController<bool> _adsRemovedController =
      StreamController<bool>.broadcast();

  @override
  Stream<bool> watchAdsRemoved() async* {
    yield _adsRemoved;
    yield* _adsRemovedController.stream;
  }

  @override
  Future<bool> getAdsRemoved() async => _adsRemoved;

  @override
  Future<void> setAdsRemoved(bool adsRemoved) async {
    _adsRemoved = adsRemoved;
    _adsRemovedController.add(adsRemoved);
  }

  @override
  Future<String?> getDeviceCredential(String deviceId) async =>
      _credentials[deviceId];

  @override
  Future<void> setDeviceCredential(String deviceId, String credential) async {
    _credentials[deviceId] = credential;
  }

  void dispose() {
    _controller.close();
    _layoutController.close();
    _adsRemovedController.close();
  }
}

/// In-memory [ILayoutRepository] — the home screen only needs the built-in
/// layouts streamed back so the active layout resolves to the classic one.
class _FakeLayoutRepository implements ILayoutRepository {
  @override
  Stream<List<RemoteLayout>> watchAllLayouts() => Stream.value(builtInLayouts);

  @override
  Future<RemoteLayout?> getLayout(String id) async {
    for (final layout in builtInLayouts) {
      if (layout.id == id) return layout;
    }
    return null;
  }

  @override
  Future<void> saveLayout(RemoteLayout layout) async {}

  @override
  Future<void> deleteLayout(String id) async {}
}

/// In-memory [ICustomImageRepository] — the home screen only needs an empty
/// image set so `CustomImage` buttons resolve to their default icons.
class _FakeCustomImageRepository implements ICustomImageRepository {
  @override
  Stream<List<StoredImage>> watchImages() => Stream.value(const []);

  @override
  Future<StoredImage?> importImage() async => null;

  @override
  Future<void> sweepOrphans(Set<String> referencedIds) async {}
}

/// Records analytics calls instead of forwarding them to Firebase.
class _FakeAnalyticsService implements AnalyticsService {
  final List<String> keysSent = [];
  final List<String> skinsChanged = [];

  @override
  Future<void> logKeySent(String key) async => keysSent.add(key);

  @override
  Future<void> logSkinChanged(String skinName) async =>
      skinsChanged.add(skinName);

  @override
  Future<void> logDeviceConnected(String deviceModel) async {}

  @override
  Future<void> logDeviceDisconnected() async {}

  @override
  Future<void> logAdViewed(String adUnitId) async {}

  @override
  Future<void> logLayoutSelected(String layoutId) async {}

  @override
  Future<void> logLayoutCreated(String layoutId) async {}

  @override
  Future<void> logLayoutEdited(String layoutId) async {}

  @override
  Future<void> logLayoutDeleted(String layoutId) async {}

  @override
  Future<void> logCustomImageAdded(String imageId) async {}

  @override
  Future<void> logPurchaseRemoveAds() async {}

  @override
  Future<void> logRestoreRemoveAds() async {}

  @override
  Future<void> logConsentResolved({required bool canRequestAds}) async {}

  @override
  FirebaseAnalyticsObserver get observer => throw UnimplementedError();
}

/// In-memory [RemoteChannel] that records every key sent, so the home
/// screen's key-press wiring can be verified without a real transport.
class _FakeRemoteChannel implements RemoteChannel {
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Every key passed to [sendKeyCommand], in order.
  final List<String> sentKeys = [];

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _events.stream;

  @override
  Future<void> sendKeyCommand(String key) async => sentKeys.add(key);

  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> connectToDevice(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async => [];

  @override
  void dispose() => _events.close();
}

/// Test [ConsentService] that always denies ad requests, so [RemoteBannerAd]
/// short-circuits to an empty [SizedBox] without touching the platform.
class _FakeConsentService extends ConsentService {
  _FakeConsentService(super.analytics);

  @override
  Future<bool> canRequestAds() async => false;

  @override
  Future<void> requestConsent() async {}
}

/// Test [IapService] that never reaches the real store. All purchase /
/// restore / query operations are no-ops, and the failure stream stays empty.
class _FakeIapService extends IapService {
  _FakeIapService(super.preferences, super.analytics);

  @override
  Future<void> init() async {}

  @override
  Future<ProductDetails?> queryProducts() async => null;

  @override
  Future<void> buyRemoveAds() async {}

  @override
  Future<void> restorePurchases() async {}
}
