import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/skin_registry.dart';
import 'package:flixsy/theming/skins/main/main_remote_skin.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteSkin contract', () {
    // Every registered skin must build a widget that satisfies the
    // RemoteSkin interface and forwards the callback it was given.
    for (final skin in AppSkin.values) {
      test('${skin.name} skin forwards its onKeyPressed callback', () {
        void callback(String key) {}
        final widget = skinRegistry[skin]!.buildRemoteSkin(
          onKeyPressed: callback,
          layout: classicLayout,
        );

        expect(widget, isA<RemoteSkin>());
        expect((widget as RemoteSkin).onKeyPressed, same(callback));
      });
    }
  });

  group('MainRemoteSkin hit testing', () {
    // The logo star is its own keyed square ('flixsyLogoPad'); tap offsets
    // are derived from its measured side as fractions of the hit-test radii:
    //   centre 'OK' circle : r <= 0.166 * side
    //   dead ring          : 0.166 * side < r < 0.190 * side
    //   directional arms   : 0.190 * side <= r <= 0.440 * side
    //   off-logo dead zone : r > 0.440 * side
    final padFinder = find.byKey(const ValueKey('flixsyLogoPad'));

    Future<List<String>> pumpSkin(WidgetTester tester) async {
      final keys = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 640,
              child: MainRemoteSkin(onKeyPressed: keys.add),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return keys;
    }

    /// The centre of the logo star and its side length, measured live so the
    /// tests stay correct regardless of how tall the control bar grows.
    ({Offset center, double side}) padGeometry(WidgetTester tester) => (
      center: tester.getCenter(padFinder),
      side: tester.getSize(padFinder).width,
    );

    testWidgets('each star point sends its directional key code', (
      tester,
    ) async {
      final keys = await pumpSkin(tester);
      final pad = padGeometry(tester);
      // r ≈ 0.30 * side: squarely inside the directional arms.
      final r = pad.side * 0.30;

      await tester.tapAt(pad.center + Offset(0, -r)); // North
      await tester.tapAt(pad.center + Offset(0, r)); // South
      await tester.tapAt(pad.center + Offset(r, 0)); // East
      await tester.tapAt(pad.center + Offset(-r, 0)); // West
      await tester.tapAt(pad.center); // Centre
      await tester.pumpAndSettle();

      expect(keys, ['UP', 'DOWN', 'NEXT', 'PREVIOUS', 'OK']);
    });

    testWidgets('diagonal gaps between arms are dead zones', (tester) async {
      final keys = await pumpSkin(tester);
      final pad = padGeometry(tester);
      // A 45° tap at arm radius: d on each axis gives r = d * √2 ≈ 0.30 side.
      final d = pad.side * 0.212;

      await tester.tapAt(pad.center + Offset(d, -d));
      await tester.tapAt(pad.center + Offset(-d, d));
      await tester.pumpAndSettle();

      expect(keys, isEmpty);
    });

    testWidgets('the ring between centre and arms is a dead zone', (
      tester,
    ) async {
      final keys = await pumpSkin(tester);
      final pad = padGeometry(tester);
      // r ≈ 0.178 * side: outside the centre circle, inside the arm edge.
      await tester.tapAt(pad.center + Offset(0, -pad.side * 0.178));
      await tester.pumpAndSettle();

      expect(keys, isEmpty);
    });

    testWidgets('taps beyond the outer arm radius are ignored', (tester) async {
      final keys = await pumpSkin(tester);
      final pad = padGeometry(tester);
      // r ≈ 0.49 * side: past the outer arm radius (0.440).
      await tester.tapAt(pad.center + Offset(0, -pad.side * 0.49));
      await tester.pumpAndSettle();

      expect(keys, isEmpty);
    });
  });

  group('MainRemoteSkin control bar', () {
    Future<List<String>> pumpSkin(WidgetTester tester) async {
      final keys = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 640,
              child: MainRemoteSkin(onKeyPressed: keys.add),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return keys;
    }

    testWidgets('renders Back, Home, Rewind and Fast Forward buttons', (
      tester,
    ) async {
      await pumpSkin(tester);

      expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.fast_rewind_outlined), findsOneWidget);
      expect(find.byIcon(Icons.fast_forward_outlined), findsOneWidget);
    });

    testWidgets('each control button sends its key code', (tester) async {
      final keys = await pumpSkin(tester);

      await tester.tap(find.byIcon(Icons.fast_rewind_outlined));
      await tester.tap(find.byIcon(Icons.arrow_back_rounded));
      await tester.tap(find.byIcon(Icons.home_outlined));
      await tester.tap(find.byIcon(Icons.fast_forward_outlined));
      await tester.pumpAndSettle();

      expect(keys, ['REWIND', 'BACK', 'HOME', 'FAST_FORWARD']);
    });
  });
}
