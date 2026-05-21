import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/l10n/generated/app_localizations.dart';
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
    // Rocker slots use non-volume actions so the semantic labels don't collide
    // with the standalone VolumeBlock below — the test taps Volume Down/Mute/Up
    // by semantic label and needs each one to resolve to a single widget.
    DpadBlock(
      up: RemoteButton(action: RemoteKey.up),
      down: RemoteButton(action: RemoteKey.down),
      left: RemoteButton(action: RemoteKey.left),
      right: RemoteButton(action: RemoteKey.right),
      ok: RemoteButton(action: RemoteKey.ok),
      volumeUp: RemoteButton(action: RemoteKey.next),
      volumeDown: RemoteButton(action: RemoteKey.previous),
      channelUp: RemoteButton(action: RemoteKey.channelUp),
      channelDown: RemoteButton(action: RemoteKey.channelDown),
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
      cells: [
        RemoteButton(action: RemoteKey.power),
        null,
      ],
    ),
  ],
);

void main() {
  Future<List<String>> pump(WidgetTester tester, RemoteLayout layout) async {
    final keys = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: ClassicTheme.themeData,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
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
      final semantics = tester.ensureSemantics();

      final keys = await pump(tester, classicLayout);

      // Buttons paint catalogue icons; captions are dropped so each button is
      // identified only by its semantic label.
      expect(find.byIcon(Icons.keyboard_arrow_up), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      const labels = [
        'Up',
        'Left',
        'OK',
        'Right',
        'Down',
        'Rewind',
        'Play/Pause',
        'Fast Forward',
      ];
      for (final label in labels) {
        await tester.tap(find.bySemanticsLabel(label));
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

      semantics.dispose();
    });

    testWidgets('renders every block type and routes volume + grid keys', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();

      final keys = await pump(tester, _everyBlockLayout);

      // The d-pad and button-row blocks rendered alongside the rest.
      expect(find.bySemanticsLabel('Up'), findsOneWidget);
      expect(find.bySemanticsLabel('Home'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel('Volume Down'));
      await tester.tap(find.bySemanticsLabel('Mute'));
      await tester.tap(find.bySemanticsLabel('Volume Up'));
      await tester.tap(find.bySemanticsLabel('Power')); // in the grid
      await tester.pumpAndSettle();

      expect(keys, ['VOLUME_DOWN', 'MUTE', 'VOLUME_UP', 'POWER']);

      semantics.dispose();
    });
  });
}
