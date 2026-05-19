import 'dart:async';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flixsy/analytics/analytics_service.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/domain/repositories/i_preferences_repository.dart';
import 'package:flixsy/features/home/screens/home_screen.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flixsy/theming/skin_registry.dart';
import 'package:flixsy/theming/skins/classic/classic_remote_skin.dart';
import 'package:flixsy/theming/skins/main/main_remote_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakePreferencesRepository preferences;
  late _FakeAnalyticsService analytics;
  late _FakeRemoteChannel channel;

  setUp(() {
    preferences = _FakePreferencesRepository();
    analytics = _FakeAnalyticsService();
    channel = _FakeRemoteChannel();
  });

  tearDown(() {
    preferences.dispose();
    channel.dispose();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesRepositoryProvider.overrideWithValue(preferences),
          analyticsServiceProvider.overrideWithValue(analytics),
          remoteChannelProvider.overrideWithValue(channel),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders the active skin — classic by default', (tester) async {
    await pumpHome(tester);

    expect(find.byType(ClassicRemoteSkin), findsOneWidget);
    expect(find.byType(MainRemoteSkin), findsNothing);
  });

  testWidgets('skin menu swaps the rendered remote and logs the change', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();

    expect(find.byType(MainRemoteSkin), findsOneWidget);
    expect(find.byType(ClassicRemoteSkin), findsNothing);
    expect(analytics.skinsChanged, contains('main'));
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

  testWidgets('main skin control buttons route through the remote channel', (
    tester,
  ) async {
    await pumpHome(tester);

    await tester.tap(find.byIcon(Icons.palette_outlined));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Main'));
    await tester.pumpAndSettle();

    // The Back/Home/transport buttons added to the main skin must reach the
    // channel exactly like the directional keys do.
    await tester.tap(find.byIcon(Icons.home_rounded));
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
  }

  AppSkin _active = AppSkin.classic;
  final StreamController<AppSkin> _controller = StreamController<AppSkin>();
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
  Future<String?> getDeviceCredential(String deviceId) async =>
      _credentials[deviceId];

  @override
  Future<void> setDeviceCredential(String deviceId, String credential) async {
    _credentials[deviceId] = credential;
  }

  void dispose() => _controller.close();
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
