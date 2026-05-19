import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/layout/remote_layout.dart';
import '../../../theming/layout_provider.dart';

/// Lists the built-in templates and the user's custom layouts, and lets the
/// user choose, duplicate, or delete one (design doc §8).
@RoutePage()
class LayoutPickerScreen extends ConsumerWidget {
  const LayoutPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layoutsAsync = ref.watch(allLayoutsProvider);
    final activeId = ref.watch(activeLayoutIdProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Layouts')),
      body: SafeArea(
        child: layoutsAsync.when(
          data: (layouts) => ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: layouts.length,
            itemBuilder: (context, index) {
              final layout = layouts[index];
              return _LayoutTile(
                layout: layout,
                isActive: layout.id == activeId,
              );
            },
          ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Could not load layouts.\n$error')),
        ),
      ),
    );
  }
}

/// A single row in the picker. Tapping the row makes the layout active —
/// the leading indicator updates in place; the overflow menu carries the
/// duplicate and delete actions.
class _LayoutTile extends ConsumerWidget {
  const _LayoutTile({required this.layout, required this.isActive});

  final RemoteLayout layout;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: Icon(
          isActive ? Icons.check_circle : Icons.radio_button_unchecked,
          color: isActive ? colors.primary : colors.onSurfaceVariant,
        ),
        title: Text(layout.name),
        subtitle: Text(
          layout.isTemplate ? 'Built-in template' : 'Custom layout',
        ),
        trailing: _LayoutMenu(layout: layout),
        onTap: () => ref.read(layoutControllerProvider).selectLayout(layout.id),
      ),
    );
  }
}

enum _LayoutAction { duplicate, delete }

/// Overflow menu for a layout row: duplicate always, delete for custom
/// layouts only — built-in templates are read-only.
class _LayoutMenu extends ConsumerWidget {
  const _LayoutMenu({required this.layout});

  final RemoteLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_LayoutAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Layout actions',
      onSelected: (action) {
        _handle(context, ref, action);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _LayoutAction.duplicate,
          child: Text('Duplicate'),
        ),
        if (!layout.isTemplate)
          const PopupMenuItem(
            value: _LayoutAction.delete,
            child: Text('Delete'),
          ),
      ],
    );
  }

  Future<void> _handle(
    BuildContext context,
    WidgetRef ref,
    _LayoutAction action,
  ) async {
    final controller = ref.read(layoutControllerProvider);
    switch (action) {
      case _LayoutAction.duplicate:
        await controller.duplicateLayout(layout);
      case _LayoutAction.delete:
        if (await _confirmDelete(context)) {
          await controller.deleteLayout(layout);
        }
    }
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete layout?'),
        content: Text('"${layout.name}" will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
