import 'package:firebase_core/firebase_core.dart';
import 'package:flixsy/firebase_options.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app.dart';
import 'core/channels/fake_connect_channel.dart';
import 'shared/providers/app_providers.dart';

/// When true, the app runs against simulated TVs instead of the real LAN
/// remote channels — useful for running in a simulator/emulator.
///
/// Enable it at launch with:
///   flutter run --dart-define=FAKE_TV=true
const _useFakeTv = bool.fromEnvironment('FAKE_TV');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await MobileAds.instance.initialize();
  } catch (e, st) {
    // A missing Firebase/AdMob config shouldn't stop the UI from launching
    // in a simulator. In release builds this is still a hard failure.
    if (kReleaseMode) rethrow;
    debugPrint('[main] Firebase/Ads init skipped (debug): $e\n$st');
  }

  final container = ProviderContainer(
    overrides: [
      if (_useFakeTv)
        remoteChannelProvider.overrideWith((ref) {
          final fake = FakeConnectChannel();
          ref.onDispose(fake.dispose);
          return fake;
        }),
    ],
  );

  // Resolve consent before the first ad request, and start the IAP listener
  // so any cold-start "restored purchase" replays land in our entitlement.
  // Failures here must not block the UI — a missing AdMob config in a
  // simulator should still let the rest of the app come up.
  try {
    await container.read(consentServiceProvider).requestConsent();
  } catch (e, st) {
    if (kReleaseMode) rethrow;
    debugPrint('[main] UMP consent skipped (debug): $e\n$st');
  }
  try {
    await container.read(iapServiceProvider).init();
  } catch (e, st) {
    if (kReleaseMode) rethrow;
    debugPrint('[main] IAP init skipped (debug): $e\n$st');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const FlixsyApp(),
    ),
  );
}
