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
        );

        expect(widget, isA<RemoteSkin>());
        expect((widget as RemoteSkin).onKeyPressed, same(callback));
      });
    }
  });

  group('MainRemoteSkin hit testing', () {
    // Pumped inside a 400px box so the skin resolves to a fixed 360px side
    // (min(400,400) * 0.9), making tap offsets from the centre deterministic.
    //
    // Geometry for side = 360:
    //   centre 'OK' circle : r <= 0.166 * 360 ≈ 60
    //   dead ring          : 60 < r < 0.190 * 360 ≈ 68
    //   directional arms   : 68 <= r <= 0.440 * 360 ≈ 158
    //   off-logo dead zone : r > 158
    Future<List<String>> pumpSkin(WidgetTester tester) async {
      final keys = <String>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 400,
                child: MainRemoteSkin(onKeyPressed: keys.add),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      return keys;
    }

    testWidgets('each star point sends its directional key code', (
      tester,
    ) async {
      final keys = await pumpSkin(tester);
      final center = tester.getCenter(find.byType(MainRemoteSkin));

      await tester.tapAt(center + const Offset(0, -100)); // North
      await tester.tapAt(center + const Offset(0, 100)); // South
      await tester.tapAt(center + const Offset(100, 0)); // East
      await tester.tapAt(center + const Offset(-100, 0)); // West
      await tester.tapAt(center); // Centre
      await tester.pumpAndSettle();

      expect(keys, ['UP', 'DOWN', 'NEXT', 'PREVIOUS', 'OK']);
    });

    testWidgets('diagonal gaps between arms are dead zones', (tester) async {
      final keys = await pumpSkin(tester);
      final center = tester.getCenter(find.byType(MainRemoteSkin));

      // 45° taps land squarely on the guarded diagonal dead band.
      await tester.tapAt(center + const Offset(70, -70));
      await tester.tapAt(center + const Offset(-70, 70));
      await tester.pumpAndSettle();

      expect(keys, isEmpty);
    });

    testWidgets('the ring between centre and arms is a dead zone', (
      tester,
    ) async {
      final keys = await pumpSkin(tester);
      final center = tester.getCenter(find.byType(MainRemoteSkin));

      // r ≈ 65 px: outside the centre circle, inside the arm inner edge.
      await tester.tapAt(center + const Offset(0, -65));
      await tester.pumpAndSettle();

      expect(keys, isEmpty);
    });

    testWidgets('taps beyond the outer arm radius are ignored', (tester) async {
      final keys = await pumpSkin(tester);
      final center = tester.getCenter(find.byType(MainRemoteSkin));

      // r = 170 px: past the outer arm radius (≈158).
      await tester.tapAt(center + const Offset(0, -170));
      await tester.pumpAndSettle();

      expect(keys, isEmpty);
    });
  });
}
