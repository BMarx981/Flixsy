class TvDevice {
  const TvDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.modelName,
    this.vendor,
  });

  final String id;
  final String name;
  final String ipAddress;
  final String modelName;

  /// Per-vendor channel id — `'webos'`, `'roku'`, `'samsung'`, `'androidtv'`.
  /// `null` when discovery did not surface a vendor (e.g. the legacy native
  /// bridge). Used to gate vendor-specific UX like the LG Wake-on-LAN setup
  /// sheet.
  final String? vendor;

  /// Parses a device event map emitted by the native ConnectSDK EventChannel.
  /// Expected keys: id, name, ipAddress, modelName, vendor (optional).
  factory TvDevice.fromMap(Map<String, dynamic> map) {
    return TvDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown TV',
      ipAddress: map['ipAddress'] as String? ?? '',
      modelName: map['modelName'] as String? ?? '',
      vendor: map['vendor'] as String?,
    );
  }
}
