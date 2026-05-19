import 'package:drift/drift.dart';

/// Stores user-created remote layouts.
///
/// Built-in templates are *not* rows here — they are `const` data in code
/// (see `built_in_layouts.dart`). "Editing" a template copies it into a row
/// of this table (design doc §7).
class CustomLayoutsTable extends Table {
  /// Stable layout id (a uuid). Built-in ids never reach this table.
  TextColumn get id => text()();

  TextColumn get name => text()();

  /// The layout's whole block tree, JSON-encoded — layouts are small, so the
  /// blocks are not normalised into their own rows.
  TextColumn get blocksJson => text()();

  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
