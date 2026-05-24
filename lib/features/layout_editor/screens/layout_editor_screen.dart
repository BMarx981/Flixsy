import 'dart:io';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/extensions/l10n_extensions.dart';
import 'package:flixsy/data/models/layout/layout_block.dart';
import 'package:flixsy/data/models/layout/remote_button.dart';
import 'package:flixsy/data/models/layout/remote_layout.dart';
import 'package:flixsy/shared/widgets/glass_surface.dart';
import 'package:flixsy/theming/custom_image_provider.dart';
import 'package:flixsy/theming/icons/remote_key_l10n.dart';
import 'package:flixsy/theming/layout_provider.dart';
import 'package:flixsy/theming/skins/classic/classic_section_renderer.dart';
import 'package:flixsy/theming/standard/button_presentation.dart';
import 'package:flixsy/theming/standard/standard_remote.dart';
import 'package:flixsy/features/layout_editor/providers/layout_editor_provider.dart';
import 'package:flixsy/features/layout_editor/widgets/block_type_sheet.dart';
import 'package:flixsy/features/layout_editor/widgets/button_editor_sheet.dart';

/// Whether [block] supports inline add/remove of its buttons in the editor —
/// true for [ButtonRowBlock] and [GridBlock], false for fixed-slot blocks.
bool _isVariable(LayoutBlock block) =>
    block is ButtonRowBlock || block is GridBlock;

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
    final foreground = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        flexibleSpace: const GlassSurface(
          borderRadius: BorderRadius.zero,
          border: false,
          shadow: false,
          child: SizedBox.expand(),
        ),
        iconTheme: IconThemeData(color: foreground),
        title: Text(
          context.l10n.editorTitle,
          style: TextStyle(color: foreground),
        ),
        actions: [
          TextButton(
            onPressed: () => _save(context, ref),
            style: TextButton.styleFrom(foregroundColor: foreground),
            child: Text(context.l10n.commonSave),
          ),
        ],
      ),
      floatingActionButton: _GlassFab(
        onPressed: () => _addBlock(context, notifier),
        icon: Icons.add,
        label: context.l10n.editorAddBlockButton,
      ),
      body: GlassBackdrop(
        child: SafeArea(
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
                  onButtonTap: (buttonIndex, button) => _editButton(
                    context,
                    notifier,
                    index,
                    buttonIndex,
                    button,
                  ),
                  onButtonRemove: (buttonIndex) =>
                      notifier.removeButton(index, buttonIndex),
                  onAddButton: () => notifier.addButton(index),
                ),
            ],
          ),
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
        SnackBar(content: Text(context.l10n.editorValidationName)),
      );
      return;
    }
    if (draft.blocks.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(context.l10n.editorValidationBlocks)),
      );
      return;
    }

    await ref.read(layoutControllerProvider).updateLayout(draft);
    if (!context.mounted) return;
    messenger.showSnackBar(
      SnackBar(content: Text(context.l10n.editorSavedSnack)),
    );
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
        Text(context.l10n.editorPreviewLabel, style: labelStyle),
        const SizedBox(height: 8),
        _PreviewBox(layout: draft),
        const SizedBox(height: 16),
        Text(context.l10n.editorBlocksLabel, style: labelStyle),
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
    final foreground = Theme.of(context).colorScheme.onSurface;
    return GlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _controller,
        style: TextStyle(color: foreground),
        decoration: InputDecoration(
          labelText: context.l10n.editorNameFieldLabel,
          labelStyle: TextStyle(color: foreground.withValues(alpha: 0.75)),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
        ),
        onChanged: (value) =>
            ref.read(layoutEditorProvider(widget.layout).notifier).rename(value),
      ),
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
    return GlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(16)),
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: layout.blocks.isEmpty
            ? Text(
                context.l10n.editorEmptyPreview,
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
    required this.onButtonRemove,
    required this.onAddButton,
  });

  final int index;
  final LayoutBlock block;
  final VoidCallback onDelete;
  final void Function(int buttonIndex, RemoteButton button) onButtonTap;
  final void Function(int buttonIndex) onButtonRemove;
  final VoidCallback onAddButton;

  @override
  Widget build(BuildContext context) {
    final buttons = block.buttons;
    final foreground = Theme.of(context).colorScheme.onSurface;
    final variable = _isVariable(block);
    final canRemove = variable && buttons.length > 1;
    final canAdd = switch (block) {
      ButtonRowBlock() => buttons.length < buttonRowMax,
      GridBlock() => buttons.length < gridMax,
      _ => false,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GlassSurface(
        padding: const EdgeInsets.fromLTRB(12, 8, 4, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _blockName(context, block),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: foreground,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  color: foreground,
                  tooltip: context.l10n.editorRemoveBlockTooltip,
                  onPressed: onDelete,
                ),
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(Icons.drag_handle, color: foreground),
                  ),
                ),
              ],
            ),
            if (buttons.isNotEmpty || canAdd)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final (i, button) in buttons.indexed)
                      if (button != null)
                        _ButtonChip(
                          button: button,
                          onTap: () => onButtonTap(i, button),
                          onRemove: canRemove ? () => onButtonRemove(i) : null,
                        )
                      else
                        const _EmptyCellChip(),
                    if (canAdd) _AddButtonChip(onTap: onAddButton),
                  ],
                ),
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
  const _ButtonChip({
    required this.button,
    required this.onTap,
    this.onRemove,
  });

  final RemoteButton button;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final imagePaths = ref.watch(customImagePathsProvider);
    final presentation = resolveButton(
      button,
      imagePaths: imagePaths,
      labelFor: context.l10n.remoteKeyLabel,
    );
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
    return _GlassChip(
      leading: avatar,
      label: presentation.semanticLabel,
      onTap: onTap,
      onRemove: onRemove,
      removeTooltip: context.l10n.editorRemoveButtonTooltip,
    );
  }
}

/// Placeholder for an empty grid cell.
class _EmptyCellChip extends StatelessWidget {
  const _EmptyCellChip();

  @override
  Widget build(BuildContext context) {
    return _GlassChip(
      leading: const Icon(Icons.add, size: 18),
      label: context.l10n.editorEmptyCell,
      onTap: null,
    );
  }
}

/// Trailing chip that appends a new button to a variable-length block.
class _AddButtonChip extends StatelessWidget {
  const _AddButtonChip({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GlassChip(
      leading: const Icon(Icons.add, size: 18),
      label: context.l10n.editorAddButtonChip,
      onTap: onTap,
    );
  }
}

/// A glassmorphic pill — the chip primitive used by every button in a block
/// card.
class _GlassChip extends StatelessWidget {
  const _GlassChip({
    required this.leading,
    required this.label,
    required this.onTap,
    this.onRemove,
    this.removeTooltip,
  });

  final Widget leading;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;
  final String? removeTooltip;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return GlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(999)),
      shadow: false,
      child: Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(999),
                right: Radius.circular(8),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  12,
                  8,
                  onRemove == null ? 12 : 8,
                  8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconTheme.merge(
                      data: IconThemeData(color: foreground),
                      child: leading,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: foreground,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            if (onRemove != null)
              InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: Tooltip(
                  message: removeTooltip ?? '',
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(2, 6, 10, 6),
                    child: Icon(
                      Icons.close,
                      size: 16,
                      color: foreground.withValues(alpha: 0.75),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A glassmorphic stand-in for [FloatingActionButton.extended].
class _GlassFab extends StatelessWidget {
  const _GlassFab({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final foreground = Theme.of(context).colorScheme.onSurface;
    return GlassSurface(
      borderRadius: const BorderRadius.all(Radius.circular(28)),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.all(Radius.circular(28)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 10),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: foreground,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _blockName(BuildContext context, LayoutBlock block) => switch (block) {
  DpadBlock() => context.l10n.blockKindDpad,
  ButtonRowBlock() => context.l10n.blockKindButtonRow,
  VolumeBlock() => context.l10n.blockKindVolume,
  GridBlock() => context.l10n.blockKindGrid,
  SpacerBlock() => context.l10n.blockKindSpacer,
};
