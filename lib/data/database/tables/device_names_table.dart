import 'package:drift/drift.dart';

/// User-assigned nicknames for discovered TVs, keyed by the device's
/// discovery id. Absence of a row means the user has not renamed it.
class DeviceNamesTable extends Table {
  TextColumn get deviceId => text()();
  TextColumn get nickname => text()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {deviceId};
}
