import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../data/models/layout/remote_layout.dart';
import '../../../router/app_router.dart';
import '../../../shared/ads/remote_banner_ad.dart';
import '../../../shared/providers/app_providers.dart';
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
    final adsRemoved = ref.watch(adsRemovedProvider).valueOrNull ?? false;

    final list = SafeArea(
      bottom: adsRemoved,
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
        error: (error, _) => Center(
          child: Text(context.l10n.layoutPickerLoadError(error.toString())),
        ),
      ),
    );

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.layoutPickerTitle)),
      body: adsRemoved
          ? list
          : Column(
              children: [
                Expanded(child: list),
                const RemoteBannerAd(),
              ],
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
          layout.isTemplate
              ? context.l10n.layoutTypeTemplate
              : context.l10n.layoutTypeCustom,
        ),
        trailing: _LayoutMenu(layout: layout),
        onTap: () => ref.read(layoutControllerProvider).selectLayout(layout.id),
      ),
    );
  }
}

enum _LayoutAction { duplicate, edit, delete }

/// Overflow menu for a layout row: duplicate always; edit and delete for
/// custom layouts only — built-in templates are read-only.
class _LayoutMenu extends ConsumerWidget {
  const _LayoutMenu({required this.layout});

  final RemoteLayout layout;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<_LayoutAction>(
      icon: const Icon(Icons.more_vert),
      tooltip: context.l10n.layoutActionsTooltip,
      onSelected: (action) {
        _handle(context, ref, action);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: _LayoutAction.duplicate,
          child: Text(context.l10n.layoutActionDuplicate),
        ),
        if (!layout.isTemplate) ...[
          PopupMenuItem(
            value: _LayoutAction.edit,
            child: Text(context.l10n.layoutActionEdit),
          ),
          PopupMenuItem(
            value: _LayoutAction.delete,
            child: Text(context.l10n.commonDelete),
          ),
        ],
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
      case _LayoutAction.edit:
        context.router.push(LayoutEditorRoute(layout: layout));
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
        title: Text(dialogContext.l10n.layoutDeleteDialogTitle),
        content: Text(dialogContext.l10n.layoutDeleteDialogBody(layout.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.l10n.commonDelete),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }
}
