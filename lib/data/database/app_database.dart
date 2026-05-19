import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'daos/layouts_dao.dart';
import 'daos/preferences_dao.dart';
import 'migrations/app_migrations.dart';
import 'tables/custom_layouts_table.dart';
import 'tables/preferences_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [PreferencesTable, CustomLayoutsTable],
  daos: [PreferencesDao, LayoutsDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// In-memory database for unit tests.
  AppDatabase.forTesting(super.connection);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => createMigrationStrategy(this);
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'flixsy.db'));
    return NativeDatabase.createInBackground(file);
  });
}
