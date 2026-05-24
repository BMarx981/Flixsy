import 'package:drift/drift.dart';

import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/database/tables/custom_layouts_table.dart';

part 'layouts_dao.g.dart';

/// Data access for user-created layouts. Stays behind [LayoutRepository] —
/// per project rules, providers and widgets never touch the DAO directly.
@DriftAccessor(tables: [CustomLayoutsTable])
class LayoutsDao extends DatabaseAccessor<AppDatabase> with _$LayoutsDaoMixin {
  LayoutsDao(super.db);

  /// Watches every custom layout, most recently updated first.
  Stream<List<CustomLayoutsTableData>> watchAll() {
    return (select(customLayoutsTable)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  /// Every custom layout, most recently updated first.
  Future<List<CustomLayoutsTableData>> getAll() {
    return (select(customLayoutsTable)..orderBy([
          (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
        ]))
        .get();
  }

  Future<CustomLayoutsTableData?> getById(String id) {
    return (select(
      customLayoutsTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
  }

  /// Inserts the layout, or replaces it if a row with the same id exists.
  Future<void> upsert(CustomLayoutsTableCompanion entry) {
    return into(customLayoutsTable).insertOnConflictUpdate(entry);
  }

  Future<void> deleteById(String id) {
    return (delete(customLayoutsTable)..where((t) => t.id.equals(id))).go();
  }
}
