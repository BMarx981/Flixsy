import 'package:flutter/material.dart';

import '../providers/layout_editor_provider.dart';

/// Shows a bottom sheet of the block types and resolves to the chosen kind —
/// or `null` if the sheet is dismissed.
Future<LayoutBlockKind?> showBlockTypeSheet(BuildContext context) {
  return showModalBottomSheet<LayoutBlockKind>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final kind in LayoutBlockKind.values)
            ListTile(
              leading: Icon(_iconFor(kind)),
              title: Text(kind.label),
              subtitle: Text(_descriptionFor(kind)),
              onTap: () => Navigator.of(sheetContext).pop(kind),
            ),
        ],
      ),
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

String _descriptionFor(LayoutBlockKind kind) => switch (kind) {
  LayoutBlockKind.dpad => 'A five-button directional cross',
  LayoutBlockKind.buttonRow => 'An evenly spaced row of buttons',
  LayoutBlockKind.volume => 'Volume down / mute / volume up',
  LayoutBlockKind.grid => 'A grid of buttons',
  LayoutBlockKind.spacer => 'Blank vertical space between blocks',
};
