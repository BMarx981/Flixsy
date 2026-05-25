import 'package:flixsy/core/channels/pointer_control.dart';
import 'package:flixsy/features/home/providers/pointer_session_provider.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/shared/widgets/pointer_aware_star_dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakePointer implements PointerControl {
  bool connected = false;
  int clicks = 0;

  @override
  Future<void> connectPointer() async {
    connected = true;
  }

  @override
  Future<void> disconnectPointer() async {
    connected = false;
  }

  @override
  Future<void> sendPointerMove(double dx, double dy) async {}

  @override
  Future<void> sendPointerClick() async {
    clicks++;
  }
}

Future<void> _pumpButton(
  WidgetTester tester, {
  required PointerControl? pointer,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [pointerControlProvider.overrideWithValue(pointer)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const Scaffold(body: Center(child: MagicMouseToggleButton())),
      ),
    ),
  );
}

void main() {
  group('MagicMouseToggleButton', () {
    testWidgets('tapping toggles the session on then off', (tester) async {
      final pointer = _FakePointer();
      await _pumpButton(tester, pointer: pointer);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MagicMouseToggleButton)),
      );

      expect(container.read(pointerSessionProvider), isFalse);

      await tester.tap(find.byType(MagicMouseToggleButton));
      await tester.pump();
      expect(container.read(pointerSessionProvider), isTrue);
      expect(pointer.connected, isTrue);

      await tester.tap(find.byType(MagicMouseToggleButton));
      await tester.pump();
      expect(container.read(pointerSessionProvider), isFalse);
      expect(pointer.connected, isFalse);
    });

    testWidgets('disabled when no pointer-capable TV is connected', (
      tester,
    ) async {
      await _pumpButton(tester, pointer: null);
      final container = ProviderScope.containerOf(
        tester.element(find.byType(MagicMouseToggleButton)),
      );

      await tester.tap(find.byType(MagicMouseToggleButton));
      await tester.pump();

      expect(container.read(pointerSessionProvider), isFalse);
    });
  });
}
