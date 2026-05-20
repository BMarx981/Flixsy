import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/theming/icons/remote_key_l10n.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every supported locale loads and resolves messages', () async {
    expect(AppLocalizations.supportedLocales, hasLength(12));

    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = await AppLocalizations.delegate.load(locale);
      final tag = locale.languageCode;

      expect(l10n.appTitle, isNotEmpty, reason: 'appTitle [$tag]');
      expect(l10n.discoveryHeaderTitle, isNotEmpty, reason: 'header [$tag]');
      // The ICU plural still selects a form in every locale.
      expect(
        l10n.discoveryDevicesFound(1),
        isNotEmpty,
        reason: 'plural1 [$tag]',
      );
      expect(
        l10n.discoveryDevicesFound(7),
        isNotEmpty,
        reason: 'plural7 [$tag]',
      );
      // A named placeholder is interpolated, not dropped.
      expect(
        l10n.discoveryPairingEnterCodeBody('Living Room TV'),
        contains('Living Room TV'),
        reason: 'placeholder [$tag]',
      );
    }
  });

  test('English plural picks singular vs plural wording', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    expect(en.discoveryDevicesFound(1), '1 device found');
    expect(en.discoveryDevicesFound(4), '4 devices found');
  });

  test('every RemoteKey and role has a non-empty localized label', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    for (final key in RemoteKey.values) {
      expect(en.remoteKeyLabel(key), isNotEmpty, reason: key.name);
    }
    for (final role in RemoteKeyRole.values) {
      expect(en.keyRoleLabel(role), isNotEmpty, reason: role.name);
    }
  });

  test('every ConnectFailure maps to a localized message', () async {
    final en = await AppLocalizations.delegate.load(const Locale('en'));
    const failures = <ConnectFailure>[
      DiscoveryFailure('log detail'),
      ConnectionFailure('log detail'),
      CommandFailure('log detail'),
      UnknownFailure('log detail'),
    ];
    for (final failure in failures) {
      expect(en.failureMessage(failure), isNotEmpty);
    }
  });

  testWidgets(
    'widget tree resolves AppLocalizations for a non-English locale',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (context) => Text(context.l10n.appTitle)),
        ),
      );
      // app_es.arb carries no translations yet, so keys fall back to English.
      expect(find.text('Flixsy'), findsOneWidget);
    },
  );
}
