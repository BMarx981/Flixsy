import '../../domain/repositories/i_preferences_repository.dart';
import '../../theming/skin_registry.dart';
import '../database/app_database.dart';

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

  AppSkin _parseSkin(String? value) {
    if (value == null) return AppSkin.classic;
    return AppSkin.values.firstWhere(
      (s) => s.name == value,
      orElse: () => AppSkin.classic,
    );
  }
}
