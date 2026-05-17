class TvDevice {
  const TvDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.modelName,
  });

  final String id;
  final String name;
  final String ipAddress;
  final String modelName;

  /// Parses a device event map emitted by the native ConnectSDK EventChannel.
  /// Expected keys: id, name, ipAddress, modelName.
  factory TvDevice.fromMap(Map<String, dynamic> map) {
    return TvDevice(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Unknown TV',
      ipAddress: map['ipAddress'] as String? ?? '',
      modelName: map['modelName'] as String? ?? '',
    );
  }
}
