import '../../theming/skin_registry.dart';

abstract interface class IPreferencesRepository {
  Stream<AppSkin> watchActiveSkin();
  Future<AppSkin> getActiveSkin();
  Future<void> setActiveSkin(AppSkin skin);

  /// Returns the stored pairing credential for [deviceId], or `null` if the
  /// device has never been paired.
  Future<String?> getDeviceCredential(String deviceId);

  /// Persists the pairing [credential] issued by [deviceId].
  Future<void> setDeviceCredential(String deviceId, String credential);
}
