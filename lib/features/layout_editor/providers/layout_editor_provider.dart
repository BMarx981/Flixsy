import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/layout/button_appearance.dart';
import '../../../data/models/layout/layout_block.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../../data/models/layout/remote_layout.dart';
import '../../../theming/remote_key.dart';

/// The kinds of block the editor can add.
enum LayoutBlockKind {
  dpad('D-pad'),
  buttonRow('Button row'),
  volume('Volume rocker'),
  grid('Grid'),
  spacer('Spacer');

  const LayoutBlockKind(this.label);

  /// Human-readable name shown in the add-block sheet.
  final String label;
}

/// Holds the editable draft of one [RemoteLayout].
///
/// The draft is seeded from the layout the editor was opened with; every
/// mutation produces a fresh immutable [RemoteLayout] in [state]. Persistence
/// is not its concern — the editor screen hands the final draft to
/// `LayoutController`.
class LayoutEditorNotifier
    extends AutoDisposeFamilyNotifier<RemoteLayout, RemoteLayout> {
  @override
  RemoteLayout build(RemoteLayout arg) => arg;

  void rename(String name) {
    state = state.copyWith(name: name);
  }

  void addBlock(LayoutBlockKind kind) {
    state = state.copyWith(blocks: [...state.blocks, _defaultBlock(kind)]);
  }

  void removeBlock(int index) {
    if (index < 0 || index >= state.blocks.length) return;
    final blocks = [...state.blocks]..removeAt(index);
    state = state.copyWith(blocks: blocks);
  }

  void reorderBlocks(int oldIndex, int newIndex) {
    final blocks = [...state.blocks];
    if (oldIndex < 0 || oldIndex >= blocks.length) return;
    // ReorderableListView reports newIndex as if the dragged item were still
    // in the list, so a downward move is one past its landing slot.
    if (newIndex > oldIndex) newIndex -= 1;
    final block = blocks.removeAt(oldIndex);
    blocks.insert(newIndex.clamp(0, blocks.length), block);
    state = state.copyWith(blocks: blocks);
  }

  /// Reassigns the action of one button, keeping its appearance intact.
  void setAction(int blockIndex, int buttonIndex, RemoteKey action) {
    if (blockIndex < 0 || blockIndex >= state.blocks.length) return;
    final block = state.blocks[blockIndex];
    if (buttonIndex < 0 || buttonIndex >= block.buttons.length) return;
    final existing = block.buttons[buttonIndex];
    final blocks = [...state.blocks];
    blocks[blockIndex] = block.withButtonAt(
      buttonIndex,
      RemoteButton(
        action: action,
        appearance: existing?.appearance ?? const DefaultLook(),
      ),
    );
    state = state.copyWith(blocks: blocks);
  }

  /// A sensible starting block for [kind]; the user reassigns from here.
  LayoutBlock _defaultBlock(LayoutBlockKind kind) {
    return switch (kind) {
      LayoutBlockKind.dpad => const DpadBlock(
        up: RemoteButton(action: RemoteKey.up),
        down: RemoteButton(action: RemoteKey.down),
        left: RemoteButton(action: RemoteKey.left),
        right: RemoteButton(action: RemoteKey.right),
        ok: RemoteButton(action: RemoteKey.ok),
      ),
      LayoutBlockKind.buttonRow => const ButtonRowBlock(
        buttons: [
          RemoteButton(action: RemoteKey.rewind),
          RemoteButton(action: RemoteKey.playPause),
          RemoteButton(action: RemoteKey.fastForward),
        ],
      ),
      LayoutBlockKind.volume => const VolumeBlock(
        volumeDown: RemoteButton(action: RemoteKey.volumeDown),
        mute: RemoteButton(action: RemoteKey.mute),
        volumeUp: RemoteButton(action: RemoteKey.volumeUp),
      ),
      LayoutBlockKind.grid => const GridBlock(
        columns: 2,
        cells: [
          RemoteButton(action: RemoteKey.back),
          RemoteButton(action: RemoteKey.home),
          RemoteButton(action: RemoteKey.rewind),
          RemoteButton(action: RemoteKey.fastForward),
        ],
      ),
      LayoutBlockKind.spacer => const SpacerBlock(height: 16),
    };
  }
}

/// Editor draft for a given layout. Keyed by the layout being edited and
/// `autoDispose`d so each editor visit starts from the stored layout.
final layoutEditorProvider = NotifierProvider.autoDispose
    .family<LayoutEditorNotifier, RemoteLayout, RemoteLayout>(
      LayoutEditorNotifier.new,
    );
