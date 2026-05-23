import 'package:flutter/material.dart';

import '../../../core/extensions/l10n_extensions.dart';
import '../../../theming/icons/icon_catalog.dart';
import '../../../theming/icons/remote_key_l10n.dart';
import '../../../theming/remote_key.dart';
import 'glass_sheet.dart';

/// Shows a bottom sheet of every [RemoteKey], grouped by role, and resolves
/// to the chosen key — or `null` if the sheet is dismissed.
Future<RemoteKey?> showActionPickerSheet(BuildContext context) {
  return showGlassModalBottomSheet<RemoteKey>(
    context: context,
    builder: (sheetContext) => ListView(
      shrinkWrap: true,
      children: [
        for (final role in RemoteKeyRole.values) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Text(
              sheetContext.l10n.keyRoleLabel(role),
              style: Theme.of(sheetContext).textTheme.labelLarge,
            ),
          ),
          for (final key in RemoteKey.values.where((k) => k.role == role))
            ListTile(
              leading: Icon(defaultIconFor(key)),
              title: Text(sheetContext.l10n.remoteKeyLabel(key)),
              onTap: () => Navigator.of(sheetContext).pop(key),
            ),
        ],
      ],
    ),
  );
}
