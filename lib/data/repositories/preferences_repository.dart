import 'package:flixsy/domain/repositories/i_preferences_repository.dart';
import 'package:flixsy/theming/skin_registry.dart';
import 'package:flixsy/data/database/app_database.dart';

class PreferencesRepository implements IPreferencesRepository {
  const PreferencesRepository(this._db);

  final AppDatabase _db;

  @override
  Stream<AppSkin> watchActiveSkin() {
    return _db.preferencesDao.watchActiveSkin().map(_parseSkin);
  }

  @override
  Future<AppSkin> getActiveSkin() async {
    final value = await _db.preferencesDao.getActiveSkin();
    return _parseSkin(value);
  }

  @override
  Future<void> setActiveSkin(AppSkin skin) {
    return _db.preferencesDao.setActiveSkin(skin.name);
  }

  @override
  Stream<String?> watchActiveLayoutId() =>
      _db.preferencesDao.watchActiveLayoutId();

  @override
  Future<String?> getActiveLayoutId() => _db.preferencesDao.getActiveLayoutId();

  @override
  Future<void> setActiveLayoutId(String layoutId) =>
      _db.preferencesDao.setActiveLayoutId(layoutId);

  @override
  Stream<bool> watchAdsRemoved() => _db.preferencesDao.watchAdsRemoved();

  @override
  Future<bool> getAdsRemoved() => _db.preferencesDao.getAdsRemoved();

  @override
  Future<void> setAdsRemoved(bool adsRemoved) =>
      _db.preferencesDao.setAdsRemoved(adsRemoved);

  @override
  Future<String?> getDeviceCredential(String deviceId) =>
      _db.preferencesDao.getDeviceCredential(deviceId);

  @override
  Future<void> setDeviceCredential(String deviceId, String credential) =>
      _db.preferencesDao.setDeviceCredential(deviceId, credential);

  AppSkin _parseSkin(String? value) {
    if (value == null) return AppSkin.classic;
    return AppSkin.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AppSkin.classic,
    );
  }
}
