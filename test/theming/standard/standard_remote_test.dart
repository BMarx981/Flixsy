import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/skins/classic/classic_section_renderer.dart';
import 'package:flixsy/theming/skins/classic/classic_theme.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A layout exercising all five block types with distinct keys.
const _everyBlockLayout = RemoteLayout(
  id: 'test:every-block',
  name: 'Every block',
  blocks: [
    DpadBlock(
      up: RemoteButton(action: RemoteKey.up),
      down: RemoteButton(action: RemoteKey.down),
      left: RemoteButton(action: RemoteKey.left),
      right: RemoteButton(action: RemoteKey.right),
      ok: RemoteButton(action: RemoteKey.ok),
    ),
    SpacerBlock(height: 8),
    ButtonRowBlock(
      buttons: [
        RemoteButton(action: RemoteKey.back),
        RemoteButton(action: RemoteKey.home),
      ],
    ),
    VolumeBlock(
      volumeDown: RemoteButton(action: RemoteKey.volumeDown),
      mute: RemoteButton(action: RemoteKey.mute),
      volumeUp: RemoteButton(action: RemoteKey.volumeUp),
    ),
    GridBlock(
      columns: 2,
      cells: [RemoteButton(action: RemoteKey.power), null],
    ),
  ],
);

void main() {
  Future<List<String>> pump(WidgetTester tester, RemoteLayout layout) async {
    final keys = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ClassicTheme.themeData,
        home: Scaffold(
          body: StandardRemote(
            layout: layout,
            renderer: const ClassicSectionRenderer(),
            onKeyPressed: keys.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return keys;
  }

  group('StandardRemote', () {
    testWidgets('satisfies the RemoteSkin contract', (tester) async {
      void callback(String key) {}
      final widget = StandardRemote(
        layout: classicLayout,
        renderer: const ClassicSectionRenderer(),
        onKeyPressed: callback,
      );

      expect(widget, isA<RemoteSkin>());
      expect(widget.onKeyPressed, same(callback));
    });

    testWidgets('renders the classic built-in layout and routes every key', (
      tester,
    ) async {
      final keys = await pump(tester, classicLayout);

      // Buttons paint catalogue icons with a caption beneath each.
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      const captions = [
        'Up',
        'Left',
        'OK',
        'Right',
        'Down',
        'Rewind',
        'Play/Pause',
        'Fast Forward',
      ];
      for (final caption in captions) {
        await tester.tap(find.text(caption));
      }
      await tester.pumpAndSettle();

      expect(keys, [
        'UP',
        'LEFT',
        'OK',
        'RIGHT',
        'DOWN',
        'REWIND',
        'PLAY_PAUSE',
        'FAST_FORWARD',
      ]);
    });

    testWidgets('renders every block type and routes volume + grid keys', (
      tester,
    ) async {
      final keys = await pump(tester, _everyBlockLayout);

      // The d-pad and button-row blocks rendered alongside the rest.
      expect(find.text('Up'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);

      await tester.tap(find.text('Volume Down'));
      await tester.tap(find.text('Mute'));
      await tester.tap(find.text('Volume Up'));
      await tester.tap(find.text('Power')); // in the grid
      await tester.pumpAndSettle();

      expect(keys, ['VOLUME_DOWN', 'MUTE', 'VOLUME_UP', 'POWER']);
    });
  });
}
