import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/connect_failure.dart';
import '../../../data/models/tv_device.dart';
import '../../../shared/providers/app_providers.dart';

enum DiscoveryStatus { scanning, idle, error }

class DiscoveryState {
  const DiscoveryState({
    this.devices = const [],
    this.status = DiscoveryStatus.scanning,
    this.connectingDeviceId,
    this.connectedDevice,
    this.failure,
  });

  final List<TvDevice> devices;
  final DiscoveryStatus status;

  /// Non-null while a connect attempt is in flight.
  final String? connectingDeviceId;

  /// Set after ConnectSDK confirms a successful connection.
  /// The screen watches for this to trigger navigation.
  final TvDevice? connectedDevice;

  final ConnectFailure? failure;

  bool get isConnecting => connectingDeviceId != null;

  DiscoveryState copyWith({
    List<TvDevice>? devices,
    DiscoveryStatus? status,
    String? connectingDeviceId,
    TvDevice? connectedDevice,
    ConnectFailure? failure,
    bool clearConnecting = false,
    bool clearFailure = false,
    bool clearConnected = false,
  }) {
    return DiscoveryState(
      devices: devices ?? this.devices,
      status: status ?? this.status,
      connectingDeviceId:
          clearConnecting ? null : connectingDeviceId ?? this.connectingDeviceId,
      connectedDevice:
          clearConnected ? null : connectedDevice ?? this.connectedDevice,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

class DeviceDiscoveryNotifier extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() {
    final channel = ref.read(connectChannelProvider);

    // Listen to native device events (added / updated / lost).
    final sub = channel.deviceEvents.listen(
      _handleDeviceEvent,
      onError: (Object e, StackTrace st) {
        debugPrint('[DeviceDiscovery] event stream error: $e');
      },
    );
    ref.onDispose(sub.cancel);
    ref.onDispose(() => channel.stopDiscovery().ignore());

    // Start discovery fire-and-forget — errors surface via state.
    _startDiscovery();

    return const DiscoveryState();
  }

  Future<void> _startDiscovery() async {
    debugPrint('[DeviceDiscovery] starting discovery...');
    try {
      await ref.read(connectChannelProvider).startDiscovery();
      debugPrint('[DeviceDiscovery] startDiscovery call returned');
    } on ConnectFailure catch (e) {
      debugPrint('[DeviceDiscovery] startDiscovery failed: $e');
      state = state.copyWith(status: DiscoveryStatus.error, failure: e);
    }
  }

  void _handleDeviceEvent(Map<String, dynamic> event) {
    debugPrint('[DeviceDiscovery] event: $event');
    final type = event['type'] as String?;
    switch (type) {
      case 'deviceFound':
      case 'deviceUpdated':
        final deviceMap = (event['device'] as Map?)?.cast<String, dynamic>();
        if (deviceMap == null) {
          debugPrint('[DeviceDiscovery] $type event missing device payload');
          return;
        }
        final device = TvDevice.fromMap(deviceMap);
        debugPrint('[DeviceDiscovery] parsed device: ${device.name} @ ${device.ipAddress} (${device.id})');
        final updated = List<TvDevice>.from(state.devices);
        final idx = updated.indexWhere((d) => d.id == device.id);
        if (idx >= 0) {
          updated[idx] = device;
        } else {
          updated.add(device);
        }
        state = state.copyWith(devices: updated);
      case 'deviceLost':
        final id = event['deviceId'] as String?;
        if (id != null) {
          state = state.copyWith(
            devices: state.devices.where((d) => d.id != id).toList(),
          );
        }
      case 'discoveryError':
        debugPrint('[DeviceDiscovery] discoveryError: ${event['message']}');
      default:
        debugPrint('[DeviceDiscovery] unhandled event type: $type');
    }
  }

  Future<void> connectToDevice(TvDevice device) async {
    if (state.isConnecting) return;
    state = state.copyWith(
      connectingDeviceId: device.id,
      clearFailure: true,
    );
    try {
      await ref.read(connectChannelProvider).connectToDevice(device.id);
      state = state.copyWith(
        clearConnecting: true,
        connectedDevice: device,
      );
    } on ConnectFailure catch (e) {
      state = state.copyWith(clearConnecting: true, failure: e);
    }
  }

  Future<void> retry() async {
    state = const DiscoveryState();
    await _startDiscovery();
  }
}

final deviceDiscoveryProvider =
    NotifierProvider<DeviceDiscoveryNotifier, DiscoveryState>(
  DeviceDiscoveryNotifier.new,
);
