import 'package:flixsy/data/models/layout/button_appearance.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/features/layout_editor/providers/layout_editor_provider.dart';
import 'package:flixsy/theming/remote_key.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const seed = RemoteLayout(
    id: 'l1',
    name: 'Draft',
    blocks: [
      ButtonRowBlock(buttons: [RemoteButton(action: RemoteKey.ok)]),
      SpacerBlock(height: 8),
    ],
  );

  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  LayoutEditorNotifier notifier() =>
      container.read(layoutEditorProvider(seed).notifier);
  RemoteLayout draft() => container.read(layoutEditorProvider(seed));

  test('seeds the draft from the layout it was opened with', () {
    expect(draft().id, 'l1');
    expect(draft().blocks, hasLength(2));
  });

  test('rename updates the draft name', () {
    notifier().rename('Living room');
    expect(draft().name, 'Living room');
  });

  test('addBlock appends a block of the chosen kind', () {
    notifier().addBlock(LayoutBlockKind.volume);
    expect(draft().blocks, hasLength(3));
    expect(draft().blocks.last, isA<VolumeBlock>());
  });

  test('removeBlock drops the block at the index', () {
    notifier().removeBlock(0);
    expect(draft().blocks, hasLength(1));
    expect(draft().blocks.single, isA<SpacerBlock>());
  });

  test('reorderBlocks moves a block to a new position', () {
    notifier().reorderBlocks(0, 2); // move the row past the spacer
    expect(draft().blocks.first, isA<SpacerBlock>());
    expect(draft().blocks.last, isA<ButtonRowBlock>());
  });

  test('setAction reassigns a button while keeping its appearance', () {
    notifier().setAction(0, 0, RemoteKey.home);
    final block = draft().blocks.first as ButtonRowBlock;
    expect(block.buttons.single.action, RemoteKey.home);
    expect(block.buttons.single.appearance, isA<DefaultLook>());
  });

  test('setAction ignores an out-of-range index without throwing', () {
    notifier().setAction(9, 0, RemoteKey.home);
    expect(draft().blocks, hasLength(2));
  });

  test('setButton replaces a button outright — action and appearance', () {
    notifier().setButton(
      0,
      0,
      const RemoteButton(
        action: RemoteKey.power,
        appearance: TextOnly(labelOverride: 'Off'),
      ),
    );
    final block = draft().blocks.first as ButtonRowBlock;
    expect(block.buttons.single.action, RemoteKey.power);
    expect(block.buttons.single.appearance, isA<TextOnly>());
  });

  test('setButton ignores an out-of-range index without throwing', () {
    notifier().setButton(9, 0, const RemoteButton(action: RemoteKey.home));
    expect(draft().blocks, hasLength(2));
  });
}
