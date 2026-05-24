import 'package:drift/drift.dart';

import 'package:flixsy/data/database/app_database.dart';

/// Builds the [AppDatabase] migration strategy.
///
/// Schema history:
/// - **v1** — `preferences_table` only.
/// - **v2** — adds `custom_layouts_table` for user-created remote layouts.
/// - **v3** — adds `custom_images_table` for user-uploaded button images.
MigrationStrategy createMigrationStrategy(AppDatabase db) {
  return MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(db.customLayoutsTable);
      }
      if (from < 3) {
        await m.createTable(db.customImagesTable);
      }
    },
  );
}
