import 'package:flutter/material.dart';

import '../../../theming/remote_key.dart';
import '../../../theming/standard/default_glyphs.dart';

const Map<RemoteKeyRole, String> _roleLabels = {
  RemoteKeyRole.dpad: 'Directional',
  RemoteKeyRole.navigation: 'Navigation',
  RemoteKeyRole.transport: 'Playback',
  RemoteKeyRole.volume: 'Volume',
  RemoteKeyRole.system: 'System',
};

/// Shows a bottom sheet of every [RemoteKey], grouped by role, and resolves
/// to the chosen key — or `null` if the sheet is dismissed.
Future<RemoteKey?> showActionPickerSheet(BuildContext context) {
  return showModalBottomSheet<RemoteKey>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          for (final role in RemoteKeyRole.values) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                _roleLabels[role] ?? role.name,
                style: Theme.of(sheetContext).textTheme.labelLarge,
              ),
            ),
            for (final key in RemoteKey.values.where((k) => k.role == role))
              ListTile(
                leading: Text(
                  defaultGlyph(key),
                  style: const TextStyle(fontSize: 20),
                ),
                title: Text(defaultLabel(key)),
                onTap: () => Navigator.of(sheetContext).pop(key),
              ),
          ],
        ],
      ),
    ),
  );
}
