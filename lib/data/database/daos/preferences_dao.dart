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

  static const _activeLayoutKey = 'active_layout';

  /// The id of the layout the user has selected — a `builtin:` template id or
  /// a custom layout's uuid. `null` until the user picks one.
  Future<String?> getActiveLayoutId() => _getValue(_activeLayoutKey);

  Future<void> setActiveLayoutId(String layoutId) =>
      _setValue(_activeLayoutKey, layoutId);

  Stream<String?> watchActiveLayoutId() => _watchValue(_activeLayoutKey);

  static const _deviceCredentialPrefix = 'device_cred:';

  /// Returns the stored pairing credential for [deviceId] — a webOS
  /// client-key, Samsung token, or Android TV cert bundle — or `null` if the
  /// device has never been paired.
  Future<String?> getDeviceCredential(String deviceId) =>
      _getValue('$_deviceCredentialPrefix$deviceId');

  /// Persists the pairing [credential] for [deviceId] so future connections
  /// can skip the on-screen pairing prompt.
  Future<void> setDeviceCredential(String deviceId, String credential) =>
      _setValue('$_deviceCredentialPrefix$deviceId', credential);

  Future<String?> _getValue(String key) async {
    final query = select(preferencesTable)..where((t) => t.key.equals(key));
    final row = await query.getSingleOrNull();
    return row?.value;
  }

  Future<void> _setValue(String key, String value) {
    return into(preferencesTable).insertOnConflictUpdate(
      PreferencesTableCompanion.insert(key: key, value: value),
    );
  }

  Stream<String?> _watchValue(String key) {
    final query = select(preferencesTable)..where((t) => t.key.equals(key));
    return query.watchSingleOrNull().map((row) => row?.value);
  }
}
