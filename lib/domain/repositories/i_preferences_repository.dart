import 'package:flixsy/theming/skin_registry.dart';

abstract interface class IPreferencesRepository {
  Stream<AppSkin> watchActiveSkin();
  Future<AppSkin> getActiveSkin();
  Future<void> setActiveSkin(AppSkin skin);

  /// The id of the layout the user has selected, or `null` if none is stored.
  /// Callers apply their own default (the classic built-in).
  Stream<String?> watchActiveLayoutId();
  Future<String?> getActiveLayoutId();
  Future<void> setActiveLayoutId(String layoutId);

  /// Whether the user has purchased the "Remove Ads" entitlement.
  Stream<bool> watchAdsRemoved();
  Future<bool> getAdsRemoved();
  Future<void> setAdsRemoved(bool adsRemoved);

  /// Returns the stored pairing credential for [deviceId], or `null` if the
  /// device has never been paired.
  Future<String?> getDeviceCredential(String deviceId);

  /// Persists the pairing [credential] issued by [deviceId].
  Future<void> setDeviceCredential(String deviceId, String credential);

  /// Returns the persisted hardware MAC address for [deviceId], or `null` if
  /// the device has never reported one. Used by Wake-on-LAN.
  Future<String?> getDeviceMacAddress(String deviceId);

  /// Persists the hardware [macAddress] for [deviceId].
  Future<void> setDeviceMacAddress(String deviceId, String macAddress);
}
