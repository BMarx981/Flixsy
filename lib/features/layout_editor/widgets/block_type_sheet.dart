import 'package:flutter/material.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../providers/layout_editor_provider.dart';
import 'glass_sheet.dart';

/// Shows a bottom sheet of the block types and resolves to the chosen kind —
/// or `null` if the sheet is dismissed.
Future<LayoutBlockKind?> showBlockTypeSheet(BuildContext context) {
  return showGlassModalBottomSheet<LayoutBlockKind>(
    context: context,
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      children: [
        for (final kind in LayoutBlockKind.values)
          ListTile(
            leading: Icon(_iconFor(kind)),
            title: Text(_labelFor(sheetContext, kind)),
            subtitle: Text(_descriptionFor(sheetContext, kind)),
            onTap: () => Navigator.of(sheetContext).pop(kind),
          ),
      ],
    ),
  );
}

IconData _iconFor(LayoutBlockKind kind) => switch (kind) {
  LayoutBlockKind.dpad => Icons.gamepad_outlined,
  LayoutBlockKind.buttonRow => Icons.view_week_outlined,
  LayoutBlockKind.volume => Icons.volume_up_outlined,
  LayoutBlockKind.grid => Icons.grid_view_outlined,
  LayoutBlockKind.spacer => Icons.space_bar,
};

String _labelFor(BuildContext context, LayoutBlockKind kind) => switch (kind) {
  LayoutBlockKind.dpad => context.l10n.blockKindDpad,
  LayoutBlockKind.buttonRow => context.l10n.blockKindButtonRow,
  LayoutBlockKind.volume => context.l10n.blockKindVolume,
  LayoutBlockKind.grid => context.l10n.blockKindGrid,
  LayoutBlockKind.spacer => context.l10n.blockKindSpacer,
};

String _descriptionFor(BuildContext context, LayoutBlockKind kind) =>
    switch (kind) {
      LayoutBlockKind.dpad => context.l10n.blockDescDpad,
      LayoutBlockKind.buttonRow => context.l10n.blockDescButtonRow,
      LayoutBlockKind.volume => context.l10n.blockDescVolume,
      LayoutBlockKind.grid => context.l10n.blockDescGrid,
      LayoutBlockKind.spacer => context.l10n.blockDescSpacer,
    };
