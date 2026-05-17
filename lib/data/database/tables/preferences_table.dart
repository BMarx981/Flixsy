import 'package:drift/drift.dart';

/// Stores key/value user preferences (e.g. active skin).
class PreferencesTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}
