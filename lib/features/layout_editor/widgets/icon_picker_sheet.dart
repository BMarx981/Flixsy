import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/layout/button_appearance.dart';
import '../../../data/models/stored_image.dart';
import '../../../theming/custom_image_provider.dart';
import '../../../theming/icons/icon_catalog.dart';
import '../../../theming/icons/icon_pack.dart';
import '../../../theming/remote_key.dart';

/// Shows a bottom sheet to pick a button's *appearance kind* — the catalogue
/// default, a `Standard`-pack icon, one of the user's images, or text-only —
/// and resolves to the chosen [ButtonAppearance], or `null` if dismissed.
///
/// The returned appearance carries no [ButtonAppearance.labelOverride]: icon
/// and label are independent (design doc §3), so the caller re-applies the
/// button's existing label.
Future<ButtonAppearance?> showIconPickerSheet(
  BuildContext context, {
  required RemoteKey action,
  required ButtonAppearance current,
}) {
  return showModalBottomSheet<ButtonAppearance>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _IconPickerSheet(action: action, current: current),
  );
}

class _IconPickerSheet extends ConsumerWidget {
  const _IconPickerSheet({required this.action, required this.current});

  final RemoteKey action;
  final ButtonAppearance current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final appearance = current;
    final selectedIconId = appearance is BuiltInIcon
        ? appearance.iconId
        : null;
    final selectedImageId = appearance is CustomImage
        ? appearance.imageId
        : null;
    final images = ref.watch(customImagesProvider).valueOrNull ?? const [];

    void choose(ButtonAppearance appearance) =>
        Navigator.of(context).pop(appearance);

    return SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text('Choose icon', style: theme.textTheme.titleMedium),
          ),
          _OptionTile(
            icon: defaultIconFor(action),
            title: 'Default',
            subtitle: 'The standard icon for this action',
            selected: appearance is DefaultLook,
            onTap: () => choose(const DefaultLook()),
          ),
          _OptionTile(
            icon: Icons.text_fields,
            title: 'Text only',
            subtitle: 'Show the label, no icon',
            selected: appearance is TextOnly,
            onTap: () => choose(const TextOnly()),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text(standardPack.name, style: theme.textTheme.labelLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in standardPack.entries)
                  _IconTile(
                    entry: entry,
                    selected: entry.id == selectedIconId,
                    onTap: () => choose(BuiltInIcon(iconId: entry.id)),
                  ),
              ],
            ),
          ),
          const Divider(height: 24),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text('Your images', style: theme.textTheme.labelLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final image in images)
                  _ImageTile(
                    image: image,
                    selected: image.id == selectedImageId,
                    onTap: () => choose(CustomImage(imageId: image.id)),
                  ),
                _AddImageTile(
                  onTap: () => _addImage(context, ref),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Imports an image and, on success, selects it for the button.
  Future<void> _addImage(BuildContext context, WidgetRef ref) async {
    final image = await ref
        .read(customImageControllerProvider)
        .importImage();
    if (image != null && context.mounted) {
      Navigator.of(context).pop(CustomImage(imageId: image.id));
    }
  }
}

/// A full-width row for the `Default` and `Text only` appearance choices.
class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: selected ? const Icon(Icons.check) : null,
      selected: selected,
      onTap: onTap,
    );
  }
}

/// Shared 80×80 selectable tile chrome for the icon and image grids.
class _GridTile extends StatelessWidget {
  const _GridTile({
    required this.selected,
    required this.onTap,
    required this.child,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 80,
        height: 80,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
          color: selected ? colors.primaryContainer : null,
        ),
        child: child,
      ),
    );
  }
}

/// One square tile in the `Standard`-pack icon grid.
class _IconTile extends StatelessWidget {
  const _IconTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final IconPackEntry entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GridTile(
      selected: selected,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(entry.icon, size: 28),
          const SizedBox(height: 4),
          Text(
            entry.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

/// One square tile showing a user-uploaded image.
class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.image,
    required this.selected,
    required this.onTap,
  });

  final StoredImage image;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GridTile(
      selected: selected,
      onTap: onTap,
      child: Image.file(
        File(image.path),
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) =>
            const Icon(Icons.broken_image_outlined, size: 28),
      ),
    );
  }
}

/// The square tile that triggers an image import.
class _AddImageTile extends StatelessWidget {
  const _AddImageTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _GridTile(
      selected: false,
      onTap: onTap,
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add_photo_alternate_outlined, size: 28),
          SizedBox(height: 4),
          Text('Add', style: TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}
