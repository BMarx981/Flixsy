import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/data/models/tv_device.dart';
import 'package:flixsy/shared/providers/active_device_provider.dart';
import 'package:flixsy/shared/providers/app_providers.dart';

enum DiscoveryStatus { scanning, idle, error }

/// How the user completes pairing with a TV that is waiting on them.
enum PairingKind {
  /// The TV is showing an Allow/Deny prompt — the user accepts it on the TV
  /// itself with the physical remote (webOS, Samsung).
  confirmOnTv,

  /// The TV is showing a code the user must type into the app (Android TV).
  enterCode,
}

/// A pairing step the user must act on before a connection can complete.
class PairingRequest {
  const PairingRequest({required this.deviceId, required this.kind});

  /// The device awaiting the pairing action.
  final String deviceId;

  /// How the user completes it.
  final PairingKind kind;
}

class DiscoveryState {
  const DiscoveryState({
    this.devices = const [],
    this.status = DiscoveryStatus.scanning,
    this.connectingDeviceId,
    this.connectedDevice,
    this.pairing,
    this.failure,
  });

  final List<TvDevice> devices;
  final DiscoveryStatus status;

  /// Non-null while a connect attempt is in flight.
  final String? connectingDeviceId;

  /// Set after the channel confirms a successful connection.
  /// The screen watches for this to trigger navigation.
  final TvDevice? connectedDevice;

  /// Non-null while a TV is waiting on a pairing action from the user —
  /// drives the on-screen pairing guidance.
  final PairingRequest? pairing;

  final ConnectFailure? failure;

  bool get isConnecting => connectingDeviceId != null;

  DiscoveryState copyWith({
    List<TvDevice>? devices,
    DiscoveryStatus? status,
    String? connectingDeviceId,
    TvDevice? connectedDevice,
    PairingRequest? pairing,
    ConnectFailure? failure,
    bool clearConnecting = false,
    bool clearConnected = false,
    bool clearPairing = false,
    bool clearFailure = false,
  }) {
    return DiscoveryState(
      devices: devices ?? this.devices,
      status: status ?? this.status,
      connectingDeviceId: clearConnecting
          ? null
          : connectingDeviceId ?? this.connectingDeviceId,
      connectedDevice: clearConnected
          ? null
          : connectedDevice ?? this.connectedDevice,
      pairing: clearPairing ? null : pairing ?? this.pairing,
      failure: clearFailure ? null : failure ?? this.failure,
    );
  }
}

class DeviceDiscoveryNotifier extends Notifier<DiscoveryState> {
  @override
  DiscoveryState build() {
    final channel = ref.read(remoteChannelProvider);

    // Listen to device events (found / updated / lost / pairing).
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
      await ref.read(remoteChannelProvider).startDiscovery();
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
        debugPrint(
          '[DeviceDiscovery] parsed device: ${device.name} '
          '@ ${device.ipAddress} (${device.id})',
        );
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
      case 'pairingRequired':
        final deviceId = event['deviceId'] as String?;
        if (deviceId == null) return;
        final kind = event['kind'] == 'enterCode'
            ? PairingKind.enterCode
            : PairingKind.confirmOnTv;
        state = state.copyWith(
          pairing: PairingRequest(deviceId: deviceId, kind: kind),
        );
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
      clearPairing: true,
    );
    try {
      await ref.read(remoteChannelProvider).connectToDevice(device.id);
      ref.read(activeDeviceProvider.notifier).set(device);
      state = state.copyWith(
        clearConnecting: true,
        clearPairing: true,
        connectedDevice: device,
      );
    } on ConnectFailure catch (e) {
      state = state.copyWith(
        clearConnecting: true,
        clearPairing: true,
        failure: e,
      );
    }
  }

  /// Submits a pairing code the user read off the TV — for a [PairingRequest]
  /// of kind [PairingKind.enterCode]. The in-flight [connectToDevice] resolves
  /// once the code is accepted.
  Future<void> submitPairingCode(String code) async {
    try {
      await ref.read(remoteChannelProvider).submitPairingCode(code);
    } on ConnectFailure catch (e) {
      state = state.copyWith(failure: e);
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
