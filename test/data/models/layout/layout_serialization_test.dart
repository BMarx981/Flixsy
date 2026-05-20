import 'package:flixsy/data/models/layout/built_in_layouts.dart';
import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter_test/flutter_test.dart';

/// A layout exercising every block type and several appearances.
const _fullLayout = RemoteLayout(
  id: 'test:full',
  name: 'Full',
  blocks: [
    DpadBlock(
      up: RemoteButton(action: RemoteKey.up),
      down: RemoteButton(action: RemoteKey.down),
      left: RemoteButton(action: RemoteKey.left),
      right: RemoteButton(action: RemoteKey.right),
      ok: RemoteButton(action: RemoteKey.ok),
    ),
    SpacerBlock(height: 12),
    ButtonRowBlock(
      buttons: [
        RemoteButton(
          action: RemoteKey.home,
          appearance: TextOnly(labelOverride: 'Menu'),
        ),
        RemoteButton(action: RemoteKey.back),
      ],
    ),
    VolumeBlock(
      volumeDown: RemoteButton(action: RemoteKey.volumeDown),
      mute: RemoteButton(
        action: RemoteKey.mute,
        appearance: BuiltInIcon(iconId: 'mute_x'),
      ),
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
  group('layout round-trips through JSON', () {
    test('the classic built-in layout is unchanged by encode/decode', () {
      final restored = RemoteLayout.fromJson(classicLayout.toJson());
      expect(restored.toJson(), equals(classicLayout.toJson()));
    });

    test('a layout with every block type survives encode/decode', () {
      final restored = RemoteLayout.fromJson(_fullLayout.toJson());
      expect(restored.toJson(), equals(_fullLayout.toJson()));
      expect(restored.blocks, hasLength(5));
    });

    test('each appearance kind survives encode/decode', () {
      const appearances = <ButtonAppearance>[
        DefaultLook(),
        DefaultLook(labelOverride: ''),
        BuiltInIcon(iconId: 'play', labelOverride: 'Go'),
        PackIcon(packId: 'nick', iconId: 'sponge'),
        CustomImage(imageId: 'img-42'),
        TextOnly(labelOverride: 'Netflix'),
      ];
      for (final appearance in appearances) {
        final restored = ButtonAppearance.fromJson(appearance.toJson());
        expect(restored.runtimeType, appearance.runtimeType);
        expect(restored.toJson(), equals(appearance.toJson()));
      }
    });

    test('a null grid cell stays null after a round-trip', () {
      const grid = GridBlock(
        columns: 3,
        cells: [
          RemoteButton(action: RemoteKey.ok),
          null,
          null,
        ],
      );
      final restored = GridBlock.fromJson(grid.toJson());
      expect(restored.cells, hasLength(3));
      expect(restored.cells[1], isNull);
      expect(restored.cells[0]?.action, RemoteKey.ok);
    });
  });

  group('deserialization is total', () {
    test('an unknown appearance kind degrades to DefaultLook', () {
      final restored = ButtonAppearance.fromJson({'kind': 'hologram'});
      expect(restored, isA<DefaultLook>());
    });

    test('a built-in icon missing its id degrades to DefaultLook', () {
      final restored = ButtonAppearance.fromJson({'kind': 'builtInIcon'});
      expect(restored, isA<DefaultLook>());
    });

    test('a button with an unknown action code does not parse', () {
      expect(RemoteButton.fromJson({'action': 'WARP_DRIVE'}), isNull);
      expect(RemoteButton.fromJson({}), isNull);
    });

    test('a button with a garbled appearance still parses as DefaultLook', () {
      final button = RemoteButton.fromJson({
        'action': 'OK',
        'appearance': 'not-a-map',
      });
      expect(button, isNotNull);
      expect(button!.appearance, isA<DefaultLook>());
    });

    test('an unknown block type is dropped', () {
      expect(LayoutBlock.fromJson({'type': 'teleporter'}), isNull);
    });

    test('a layout drops unreadable blocks instead of throwing', () {
      final restored = RemoteLayout.fromJson({
        'id': 'x',
        'name': 'Mixed',
        'blocks': [
          {'type': 'spacer', 'height': 10},
          {'type': 'teleporter'},
          {'type': 'buttonRow', 'buttons': []},
        ],
      });
      expect(restored.blocks, hasLength(2));
    });

    test('a button row drops entries with no resolvable action', () {
      final block = ButtonRowBlock.fromJson({
        'type': 'buttonRow',
        'buttons': [
          {'action': 'OK'},
          {'action': 'WARP_DRIVE'},
          {'action': 'HOME'},
        ],
      });
      expect(block.buttons.map((b) => b.action), [
        RemoteKey.ok,
        RemoteKey.home,
      ]);
    });

    test('a d-pad slot falls back to its canonical key', () {
      final block = DpadBlock.fromJson({'type': 'dpad'});
      expect(block.up.action, RemoteKey.up);
      expect(block.ok.action, RemoteKey.ok);
    });

    test('a negative spacer height is clamped to zero', () {
      final block = SpacerBlock.fromJson({'type': 'spacer', 'height': -40});
      expect(block.height, 0);
    });

    test('an empty map yields a usable, empty layout', () {
      final restored = RemoteLayout.fromJson({});
      expect(restored.blocks, isEmpty);
      expect(restored.name, isNotEmpty);
    });
  });
}
