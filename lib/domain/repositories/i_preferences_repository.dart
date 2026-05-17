import '../../theming/skin_registry.dart';

abstract interface class IPreferencesRepository {
  Stream<AppSkin> watchActiveSkin();
  Future<AppSkin> getActiveSkin();
  Future<void> setActiveSkin(AppSkin skin);
}
