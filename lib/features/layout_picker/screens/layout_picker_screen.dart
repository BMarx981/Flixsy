import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../data/models/layout/remote_layout.dart';
import '../../../router/app_router.dart';
import '../../../shared/ads/remote_banner_ad.dart';
import '../../../shared/providers/app_providers.dart';
import '../../../shared/widgets/glass_popup_menu.dart';
import '../../../shared/widgets/glass_surface.dart';
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
    final foreground = Theme.of(context).colorScheme.onSurface;

    final list = SafeArea(
      bottom: adsRemoved,
      child: layoutsAsync.when(
        data: (layouts) => ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
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
          context.l10n.layoutPickerTitle,
          style: TextStyle(color: foreground),
        ),
      ),
      body: GlassBackdrop(
        child: adsRemoved
            ? list
            : Column(
                children: [
                  Expanded(child: list),
                  const RemoteBannerAd(),
                ],
              ),
      ),
    );
  }
}

/// A single row in the picker. Tapping the row makes the layout active —
/// the leading indicator updates in place; the trailing menu carries the
/// edit, duplicate, and delete actions.
class _LayoutTile extends ConsumerWidget {
  const _LayoutTile({required this.layout, required this.isActive});

  final RemoteLayout layout;
  final bool isActive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
    final subtitle = layout.isTemplate
        ? context.l10n.layoutTypeTemplate
        : context.l10n.layoutTypeCustom;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GlassSurface(
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () =>
                ref.read(layoutControllerProvider).selectLayout(layout.id),
            borderRadius: const BorderRadius.all(Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
              child: Row(
                children: [
                  _ActiveIndicator(isActive: isActive),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          layout.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: foreground,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: foreground.withValues(alpha: 0.65),
                                  ),
                        ),
                      ],
                    ),
                  ),
                  _LayoutMenu(layout: layout),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A soft glass disc that fills with a check when the layout is active.
class _ActiveIndicator extends StatelessWidget {
  const _ActiveIndicator({required this.isActive});

  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final ringColor = isActive
        ? colors.primary
        : (isDark
            ? Colors.white.withValues(alpha: 0.35)
            : Colors.white.withValues(alpha: 0.75));
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive
            ? colors.primary.withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.10),
        border: Border.all(color: ringColor, width: 1.5),
      ),
      child: isActive
          ? Icon(Icons.check, size: 16, color: colors.onPrimary)
          : null,
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
    final triggerIcon = layout.isTemplate
        ? Icons.copy_rounded
        : Icons.edit_outlined;
    return GlassPopupMenu<_LayoutAction>(
      icon: Icon(triggerIcon),
      tooltip: context.l10n.layoutActionsTooltip,
      onSelected: (action) => _handle(context, ref, action),
      items: [
        GlassPopupMenuItem(
          value: _LayoutAction.duplicate,
          icon: Icons.copy_rounded,
          label: context.l10n.layoutActionDuplicate,
        ),
        if (!layout.isTemplate) ...[
          GlassPopupMenuItem(
            value: _LayoutAction.edit,
            icon: Icons.edit_outlined,
            label: context.l10n.layoutActionEdit,
          ),
          GlassPopupMenuItem(
            value: _LayoutAction.delete,
            icon: Icons.delete_outline,
            label: context.l10n.commonDelete,
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
