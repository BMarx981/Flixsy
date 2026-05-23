import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/layout/button_appearance.dart';
import '../../../data/models/layout/layout_block.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../../data/models/layout/remote_layout.dart';
import '../../../theming/remote_key.dart';

/// The kinds of block the editor can add.
///
/// The localized name and description shown in the add-block sheet are
/// resolved in `block_type_sheet.dart` — see `lib/l10n/app_en.arb`.
enum LayoutBlockKind { dpad, buttonRow, volume, grid, spacer }

/// Maximum number of buttons in a [ButtonRowBlock] — five fits comfortably on
/// a narrow phone without the buttons shrinking into uselessness.
const int buttonRowMax = 5;

/// Maximum number of cells in a [GridBlock] — a soft cap that keeps a grid
/// from growing absurdly tall in the editor.
const int gridMax = 24;

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

  /// Replaces one button outright — its action *and* appearance.
  void setButton(int blockIndex, int buttonIndex, RemoteButton button) {
    if (blockIndex < 0 || blockIndex >= state.blocks.length) return;
    final block = state.blocks[blockIndex];
    if (buttonIndex < 0 || buttonIndex >= block.buttons.length) return;
    final blocks = [...state.blocks];
    blocks[blockIndex] = block.withButtonAt(buttonIndex, button);
    state = state.copyWith(blocks: blocks);
  }

  /// Appends a button to a [ButtonRowBlock] (up to [buttonRowMax]) or a cell
  /// to a [GridBlock] (up to [gridMax]). Other block kinds are left alone.
  void addButton(int blockIndex) {
    if (blockIndex < 0 || blockIndex >= state.blocks.length) return;
    final block = state.blocks[blockIndex];
    final next = switch (block) {
      ButtonRowBlock() when block.buttons.length < buttonRowMax =>
        ButtonRowBlock(
          buttons: [...block.buttons, const RemoteButton(action: RemoteKey.ok)],
        ),
      GridBlock() when block.cells.length < gridMax => GridBlock(
        columns: block.columns,
        cells: [...block.cells, const RemoteButton(action: RemoteKey.ok)],
      ),
      _ => null,
    };
    if (next == null) return;
    final blocks = [...state.blocks];
    blocks[blockIndex] = next;
    state = state.copyWith(blocks: blocks);
  }

  /// Removes the button at [buttonIndex] from a [ButtonRowBlock] or a cell
  /// from a [GridBlock]. Each is kept at a minimum of one entry so the row
  /// never collapses to nothing; other block kinds are left alone.
  void removeButton(int blockIndex, int buttonIndex) {
    if (blockIndex < 0 || blockIndex >= state.blocks.length) return;
    final block = state.blocks[blockIndex];
    final next = switch (block) {
      ButtonRowBlock() when block.buttons.length > 1 => ButtonRowBlock(
        buttons: [...block.buttons]..removeAt(buttonIndex),
      ),
      GridBlock() when block.cells.length > 1 => GridBlock(
        columns: block.columns,
        cells: [...block.cells]..removeAt(buttonIndex),
      ),
      _ => null,
    };
    if (next == null) return;
    final blocks = [...state.blocks];
    blocks[blockIndex] = next;
    state = state.copyWith(blocks: blocks);
  }

  /// Reassigns the action of one button, keeping its appearance intact.
  void setAction(int blockIndex, int buttonIndex, RemoteKey action) {
    if (blockIndex < 0 || blockIndex >= state.blocks.length) return;
    final block = state.blocks[blockIndex];
    if (buttonIndex < 0 || buttonIndex >= block.buttons.length) return;
    final existing = block.buttons[buttonIndex];
    setButton(
      blockIndex,
      buttonIndex,
      RemoteButton(
        action: action,
        appearance: existing?.appearance ?? const DefaultLook(),
      ),
    );
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
        volumeUp: RemoteButton(action: RemoteKey.volumeUp),
        volumeDown: RemoteButton(action: RemoteKey.volumeDown),
        channelUp: RemoteButton(action: RemoteKey.channelUp),
        channelDown: RemoteButton(action: RemoteKey.channelDown),
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
