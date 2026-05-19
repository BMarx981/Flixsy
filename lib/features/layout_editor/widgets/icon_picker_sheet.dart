import 'package:flutter/material.dart';

import '../../../data/models/layout/button_appearance.dart';
import '../../../theming/icons/icon_catalog.dart';
import '../../../theming/icons/icon_pack.dart';
import '../../../theming/remote_key.dart';

/// Shows a bottom sheet to pick a button's *appearance kind* — the catalogue
/// default, a `Standard`-pack icon, or text-only — and resolves to the chosen
/// [ButtonAppearance], or `null` if dismissed.
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

class _IconPickerSheet extends StatelessWidget {
  const _IconPickerSheet({required this.action, required this.current});

  final RemoteKey action;
  final ButtonAppearance current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appearance = current;
    final selectedIconId = appearance is BuiltInIcon
        ? appearance.iconId
        : null;

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
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
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
        ],
      ),
    );
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
      ),
    );
  }
}
