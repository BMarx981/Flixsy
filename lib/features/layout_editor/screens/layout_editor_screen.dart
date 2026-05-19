import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/layout/layout_block.dart';
import '../../../data/models/layout/remote_button.dart';
import '../../../data/models/layout/remote_layout.dart';
import '../../../theming/custom_image_provider.dart';
import '../../../theming/layout_provider.dart';
import '../../../theming/skins/classic/classic_section_renderer.dart';
import '../../../theming/standard/button_presentation.dart';
import '../../../theming/standard/standard_remote.dart';
import '../providers/layout_editor_provider.dart';
import '../widgets/block_type_sheet.dart';
import '../widgets/button_editor_sheet.dart';

/// Edits one custom layout: rename it, add / remove / reorder blocks, and
/// reassign each button's action, with a live preview (design doc §8).
@RoutePage()
class LayoutEditorScreen extends ConsumerWidget {
  const LayoutEditorScreen({super.key, required this.layout});

  /// The layout being edited — the editor draft is seeded from it.
  final RemoteLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(layoutEditorProvider(layout));
    final notifier = ref.read(layoutEditorProvider(layout).notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit layout'),
        actions: [
          TextButton(
            onPressed: () => _save(context, ref),
            child: const Text('Save'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addBlock(context, notifier),
        icon: const Icon(Icons.add),
        label: const Text('Add block'),
      ),
      body: SafeArea(
        child: ReorderableListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          onReorder: notifier.reorderBlocks,
          header: _EditorHeader(layout: layout, draft: draft),
          children: [
            for (final (index, block) in draft.blocks.indexed)
              _BlockCard(
                key: ObjectKey(block),
                index: index,
                block: block,
                onDelete: () => notifier.removeBlock(index),
                onButtonTap: (buttonIndex, button) =>
                    _editButton(context, notifier, index, buttonIndex, button),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _addBlock(
    BuildContext context,
    LayoutEditorNotifier notifier,
  ) async {
    final kind = await showBlockTypeSheet(context);
    if (kind != null) notifier.addBlock(kind);
  }

  Future<void> _editButton(
    BuildContext context,
    LayoutEditorNotifier notifier,
    int blockIndex,
    int buttonIndex,
    RemoteButton button,
  ) async {
    final edited = await showButtonEditorSheet(context, button: button);
    if (edited != null) notifier.setButton(blockIndex, buttonIndex, edited);
  }

  Future<void> _save(BuildContext context, WidgetRef ref) async {
    final draft = ref.read(layoutEditorProvider(layout));
    final messenger = ScaffoldMessenger.of(context);

    if (draft.name.trim().isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Give the layout a name.')),
      );
      return;
    }
    if (draft.blocks.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Add at least one block before saving.')),
      );
      return;
    }

    await ref.read(layoutControllerProvider).updateLayout(draft);
    messenger.showSnackBar(const SnackBar(content: Text('Layout saved.')));
  }
}

/// The non-reorderable top of the editor: name field and live preview.
class _EditorHeader extends StatelessWidget {
  const _EditorHeader({required this.layout, required this.draft});

  final RemoteLayout layout;
  final RemoteLayout draft;

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context).textTheme.labelLarge;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _NameField(layout: layout),
        const SizedBox(height: 16),
        Text('Preview', style: labelStyle),
        const SizedBox(height: 8),
        _PreviewBox(layout: draft),
        const SizedBox(height: 16),
        Text('Blocks', style: labelStyle),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// Owns the name [TextEditingController]; pushes edits into the draft.
class _NameField extends ConsumerStatefulWidget {
  const _NameField({required this.layout});

  final RemoteLayout layout;

  @override
  ConsumerState<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends ConsumerState<_NameField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: ref.read(layoutEditorProvider(widget.layout)).name,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      decoration: const InputDecoration(
        labelText: 'Layout name',
        border: OutlineInputBorder(),
      ),
      onChanged: (value) => ref
          .read(layoutEditorProvider(widget.layout).notifier)
          .rename(value),
    );
  }
}

/// A read-only render of the draft, so edits are visible immediately.
class _PreviewBox extends ConsumerWidget {
  const _PreviewBox({required this.layout});

  final RemoteLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final imagePaths = ref.watch(customImagePathsProvider);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: layout.blocks.isEmpty
          ? Text(
              'Add a block to see a preview',
              style: TextStyle(color: colors.onSurfaceVariant),
            )
          : IgnorePointer(
              child: StandardRemote(
                layout: layout,
                renderer: const ClassicSectionRenderer(),
                onKeyPressed: (_) {},
                imagePaths: imagePaths,
              ),
            ),
    );
  }
}

/// One reorderable block: its type, a delete control, a drag handle, and its
/// buttons as tappable chips.
class _BlockCard extends StatelessWidget {
  const _BlockCard({
    super.key,
    required this.index,
    required this.block,
    required this.onDelete,
    required this.onButtonTap,
  });

  final int index;
  final LayoutBlock block;
  final VoidCallback onDelete;
  final void Function(int buttonIndex, RemoteButton button) onButtonTap;

  @override
  Widget build(BuildContext context) {
    final buttons = block.buttons;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _blockName(block),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Remove block',
                  onPressed: onDelete,
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: const Padding(
                    padding: EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle),
                  ),
                ),
              ],
            ),
            if (buttons.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final (i, button) in buttons.indexed)
                    if (button != null)
                      _ButtonChip(
                        button: button,
                        onTap: () => onButtonTap(i, button),
                      )
                    else
                      const _EmptyCellChip(),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A tappable chip for one button — shows its resolved icon/image and label;
/// tapping it opens the button editor.
class _ButtonChip extends ConsumerWidget {
  const _ButtonChip({required this.button, required this.onTap});

  final RemoteButton button;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePaths = ref.watch(customImagePathsProvider);
    final presentation = resolveButton(button, imagePaths: imagePaths);
    final avatar = switch (presentation.glyph) {
      IconGlyph(:final icon) => Icon(icon, size: 18),
      ImageGlyph(:final path) => SizedBox(
        width: 18,
        height: 18,
        child: Image.file(
          File(path),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) =>
              const Icon(Icons.broken_image_outlined, size: 18),
        ),
      ),
      TextGlyph() => const Icon(Icons.text_fields, size: 18),
    };
    return ActionChip(
      avatar: avatar,
      label: Text(presentation.semanticLabel),
      onPressed: onTap,
    );
  }
}

/// Placeholder for an empty grid cell.
class _EmptyCellChip extends StatelessWidget {
  const _EmptyCellChip();

  @override
  Widget build(BuildContext context) {
    return const Chip(
      avatar: Icon(Icons.add, size: 18),
      label: Text('Empty'),
    );
  }
}

String _blockName(LayoutBlock block) => switch (block) {
  DpadBlock() => 'D-pad',
  ButtonRowBlock() => 'Button row',
  VolumeBlock() => 'Volume rocker',
  GridBlock() => 'Grid',
  SpacerBlock() => 'Spacer',
};
