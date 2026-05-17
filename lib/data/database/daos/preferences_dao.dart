import 'package:drift/drift.dart';

import '../app_database.dart';
import '../tables/preferences_table.dart';

part 'preferences_dao.g.dart';

@DriftAccessor(tables: [PreferencesTable])
class PreferencesDao extends DatabaseAccessor<AppDatabase>
    with _$PreferencesDaoMixin {
  PreferencesDao(super.db);

  static const _activeSkinKey = 'active_skin';

  Future<String?> getActiveSkin() => _getValue(_activeSkinKey);

  Future<void> setActiveSkin(String skinName) =>
      _setValue(_activeSkinKey, skinName);

  Stream<String?> watchActiveSkin() => _watchValue(_activeSkinKey);

  Future<String?> _getValue(String key) async {
    final query = select(preferencesTable)
      ..where((t) => t.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<void> _setValue(String key, String value) {
    return into(preferencesTable).insertOnConflictUpdate(
      PreferencesTableCompanion.insert(key: key, value: value),
    );
  }

  Stream<String?> _watchValue(String key) {
    final query = select(preferencesTable)
      ..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }
}
