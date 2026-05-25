import 'package:drift/drift.dart';

import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/database/tables/device_names_table.dart';

part 'device_names_dao.g.dart';

@DriftAccessor(tables: [DeviceNamesTable])
class DeviceNamesDao extends DatabaseAccessor<AppDatabase>
    with _$DeviceNamesDaoMixin {
  DeviceNamesDao(super.db);

  /// Emits the full nickname map (deviceId → nickname) any time it changes.
  /// Returning a single map keeps consumers from holding a row stream per
  /// device.
  Stream<Map<String, String>> watchAll() {
    return select(deviceNamesTable).watch().map(
          (rows) => {for (final r in rows) r.deviceId: r.nickname},
        );
  }

  Future<Map<String, String>> getAll() async {
    final rows = await select(deviceNamesTable).get();
    return {for (final r in rows) r.deviceId: r.nickname};
  }

  Future<void> setNickname(String deviceId, String nickname) {
    return into(deviceNamesTable).insertOnConflictUpdate(
      DeviceNamesTableCompanion.insert(
        deviceId: deviceId,
        nickname: nickname,
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> clearNickname(String deviceId) {
    return (delete(deviceNamesTable)
          ..where((t) => t.deviceId.equals(deviceId)))
        .go();
  }
}
