import 'package:flixsy/l10n/generated/app_localizations.dart';
import 'package:flixsy/shared/widgets/spinnable_star_dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Centre of the standard 200 px D-pad used in these tests — that's where the
/// OK / spin region lives.
const Offset _centre = Offset(100, 100);

Future<void> _pumpDpad(
  WidgetTester tester, {
  required VoidCallback onOk,
  required VoidCallback onScrollUp,
  required VoidCallback onScrollDown,
  VoidCallback? onOkLongPress,
  VoidCallback? onOkLongPressEnd,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: Center(
          child: SpinnableStarDpad(
            size: 200,
            onUp: () {},
            onDown: () {},
            onLeft: () {},
            onRight: () {},
            onOk: onOk,
            onScrollUp: onScrollUp,
            onScrollDown: onScrollDown,
            onScrollLeft: () {},
            onScrollRight: () {},
            onOkLongPress: onOkLongPress,
            onOkLongPressEnd: onOkLongPressEnd,
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('long-press OK', () {
    testWidgets(
      'fires onOkLongPress after the hold duration on the centre disc',
      (tester) async {
        var pressed = 0;
        var released = 0;
        await _pumpDpad(
          tester,
          onOk: () {},
          onScrollUp: () {},
          onScrollDown: () {},
          onOkLongPress: () => pressed++,
          onOkLongPressEnd: () => released++,
        );

        final gesture = await tester.startGesture(tester.getCenter(
          find.byType(SpinnableStarDpad),
        ));
        await tester.pump(SpinnableStarDpad.longPressDuration);
        expect(pressed, 1);

        await gesture.up();
        await tester.pump();
        expect(released, 1);
      },
    );

    testWidgets(
      'a quick OK tap does not fire onOkLongPress and still fires onOk',
      (tester) async {
        var pressed = 0;
        var ok = 0;
        await _pumpDpad(
          tester,
          onOk: () => ok++,
          onScrollUp: () {},
          onScrollDown: () {},
          onOkLongPress: () => pressed++,
          onOkLongPressEnd: () {},
        );

        await tester.tapAt(tester.getCenter(find.byType(SpinnableStarDpad)));
        await tester.pump();

        expect(pressed, 0);
        expect(ok, 1);
      },
    );

    testWidgets(
      'spinning before the hold expires cancels the long-press',
      (tester) async {
        var pressed = 0;
        var scrollDown = 0;
        await _pumpDpad(
          tester,
          onOk: () {},
          onScrollUp: () {},
          onScrollDown: () => scrollDown++,
          onOkLongPress: () => pressed++,
          onOkLongPressEnd: () {},
        );

        final dpad = find.byType(SpinnableStarDpad);
        final origin = tester.getCenter(dpad);
        final gesture = await tester.startGesture(origin);

        // A vertical drag downward — locks to the vertical axis past the
        // tap-slop threshold and emits onScrollDown ticks once cumulative
        // travel exceeds `pixelsPerTick`.
        for (var i = 1; i <= 12; i++) {
          await gesture.moveTo(origin + Offset(0, i * 8.0));
          await tester.pump(const Duration(milliseconds: 10));
        }

        await tester.pump(SpinnableStarDpad.longPressDuration);
        await gesture.up();
        await tester.pump();

        expect(scrollDown, greaterThan(0));
        expect(pressed, 0);
      },
    );

    testWidgets(
      'after a long-press session ends, OK is not fired on release',
      (tester) async {
        var ok = 0;
        await _pumpDpad(
          tester,
          onOk: () => ok++,
          onScrollUp: () {},
          onScrollDown: () {},
          onOkLongPress: () {},
          onOkLongPressEnd: () {},
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SpinnableStarDpad)),
        );
        await tester.pump(SpinnableStarDpad.longPressDuration);
        await gesture.up();
        await tester.pump();

        expect(ok, 0);
      },
    );

    testWidgets(
      'without onOkLongPress, long press is ignored and OK still fires',
      (tester) async {
        var ok = 0;
        await _pumpDpad(
          tester,
          onOk: () => ok++,
          onScrollUp: () {},
          onScrollDown: () {},
          // onOkLongPress intentionally null
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(SpinnableStarDpad)),
        );
        await tester.pump(SpinnableStarDpad.longPressDuration);
        await gesture.up();
        await tester.pump();

        expect(ok, 1);
      },
    );
  });
}

// Silence the unused-private-member analyzer for callers that don't use [_centre].
// ignore_for_file: unused_element
