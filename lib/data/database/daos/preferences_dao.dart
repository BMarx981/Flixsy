import 'package:drift/drift.dart';

import 'package:flixsy/data/database/app_database.dart';
import 'package:flixsy/data/database/tables/preferences_table.dart';

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

  static const _adsRemovedKey = 'ads_removed';

  /// Whether the user has purchased the "Remove Ads" entitlement.
  Future<bool> getAdsRemoved() async {
    final value = await _getValue(_adsRemovedKey);
    return value == 'true';
  }

  Future<void> setAdsRemoved(bool adsRemoved) =>
      _setValue(_adsRemovedKey, adsRemoved ? 'true' : 'false');

  Stream<bool> watchAdsRemoved() =>
      _watchValue(_adsRemovedKey).map((value) => value == 'true');

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

  static const _deviceMacPrefix = 'device_mac:';

  /// Returns the persisted hardware MAC address for [deviceId], or `null` if
  /// the device has never reported one. Used by Wake-on-LAN to power a TV
  /// back on while it is in standby and the SSAP socket is unreachable.
  Future<String?> getDeviceMacAddress(String deviceId) =>
      _getValue('$_deviceMacPrefix$deviceId');

  /// Persists the hardware [macAddress] for [deviceId] (in the canonical
  /// `aa:bb:cc:dd:ee:ff` form).
  Future<void> setDeviceMacAddress(String deviceId, String macAddress) =>
      _setValue('$_deviceMacPrefix$deviceId', macAddress);

  static const _powerSetupSeenPrefix = 'power_setup_seen:';

  /// Whether the user has already seen the Wake-on-LAN setup sheet for
  /// [vendor] (e.g. `'webos'`). Used so the sheet only auto-opens on the
  /// first successful connection to a TV of that brand.
  Future<bool> getPowerSetupSeen(String vendor) async {
    final value = await _getValue('$_powerSetupSeenPrefix$vendor');
    return value == 'true';
  }

  /// Marks the power-setup sheet for [vendor] as seen so it does not
  /// auto-open again. The user can still reopen it on demand.
  Future<void> setPowerSetupSeen(String vendor) =>
      _setValue('$_powerSetupSeenPrefix$vendor', 'true');

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
