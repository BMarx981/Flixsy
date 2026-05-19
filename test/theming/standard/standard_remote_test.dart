import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flixsy/theming/remote_skin.dart';
import 'package:flixsy/theming/skins/classic/classic_section_renderer.dart';
import 'package:flixsy/theming/skins/classic/classic_theme.dart';
import 'package:flixsy/theming/standard/default_glyphs.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A layout exercising all five block types with distinct glyphs.
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

      for (final glyph in ['▲', '◀', 'OK', '▶', '▼', '⏪', '⏯', '⏩']) {
        expect(find.text(glyph), findsOneWidget);
      }

      for (final glyph in ['▲', '◀', 'OK', '▶', '▼', '⏪', '⏯', '⏩']) {
        await tester.tap(find.text(glyph));
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
      expect(find.text('▲'), findsOneWidget);
      expect(find.text('⌂'), findsOneWidget);

      await tester.tap(find.text('－')); // volume down
      await tester.tap(find.text('🔇')); // mute
      await tester.tap(find.text('＋')); // volume up
      await tester.tap(find.text('⏻')); // power, in the grid
      await tester.pumpAndSettle();

      expect(keys, ['VOLUME_DOWN', 'MUTE', 'VOLUME_UP', 'POWER']);
    });
  });

  group('buttonGlyph', () {
    test('DefaultLook resolves to the action default glyph', () {
      expect(
        buttonGlyph(const RemoteButton(action: RemoteKey.playPause)),
        '⏯',
      );
    });

    test('TextOnly resolves to its label override', () {
      expect(
        buttonGlyph(
          const RemoteButton(
            action: RemoteKey.home,
            appearance: TextOnly(labelOverride: 'Menu'),
          ),
        ),
        'Menu',
      );
    });

    test('TextOnly with no override uses the action default label', () {
      expect(
        buttonGlyph(
          const RemoteButton(
            action: RemoteKey.home,
            appearance: TextOnly(),
          ),
        ),
        'Home',
      );
    });

    test('an unresolvable icon appearance falls back to the glyph', () {
      expect(
        buttonGlyph(
          const RemoteButton(
            action: RemoteKey.power,
            appearance: BuiltInIcon(iconId: 'nonexistent'),
          ),
        ),
        '⏻',
      );
    });
  });
}
