import 'dart:async';

import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/features/device_discovery/providers/device_discovery_provider.dart';
import 'package:flixsy/shared/providers/app_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// Verifies that the discovery notifier turns a `pairingRequired` channel event
// into the on-screen pairing state — the glue behind the pairing UX.

Future<void> _settle() => Future<void>.delayed(Duration.zero);

ProviderContainer _container(_FakeChannel channel) => ProviderContainer(
  overrides: [remoteChannelProvider.overrideWithValue(channel)],
);

void main() {
  test('a pairingRequired event populates state.pairing', () async {
    final channel = _FakeChannel();
    final container = _container(channel);
    addTearDown(container.dispose);
    container.read(deviceDiscoveryProvider);

    channel.emit({
      'type': 'pairingRequired',
      'deviceId': 'tv-1',
      'kind': 'confirmOnTv',
    });
    await _settle();

    final pairing = container.read(deviceDiscoveryProvider).pairing;
    expect(pairing, isNotNull);
    expect(pairing!.deviceId, 'tv-1');
    expect(pairing.kind, PairingKind.confirmOnTv);
  });

  test('a pairingRequired event of kind enterCode maps through', () async {
    final channel = _FakeChannel();
    final container = _container(channel);
    addTearDown(container.dispose);
    container.read(deviceDiscoveryProvider);

    channel.emit({
      'type': 'pairingRequired',
      'deviceId': 'tv-1',
      'kind': 'enterCode',
    });
    await _settle();

    expect(
      container.read(deviceDiscoveryProvider).pairing!.kind,
      PairingKind.enterCode,
    );
  });

  test('a successful connect clears the pairing state', () async {
    final channel = _FakeChannel();
    final container = _container(channel);
    addTearDown(container.dispose);
    final notifier = container.read(deviceDiscoveryProvider.notifier);

    channel.emit({
      'type': 'deviceFound',
      'device': {
        'id': 'tv-1',
        'name': 'Living Room',
        'ipAddress': '10.0.0.2',
        'modelName': '',
      },
    });
    channel.emit({
      'type': 'pairingRequired',
      'deviceId': 'tv-1',
      'kind': 'confirmOnTv',
    });
    await _settle();
    expect(container.read(deviceDiscoveryProvider).pairing, isNotNull);

    final device = container.read(deviceDiscoveryProvider).devices.single;
    await notifier.connectToDevice(device);

    final state = container.read(deviceDiscoveryProvider);
    expect(state.pairing, isNull);
    expect(state.connectedDevice, isNotNull);
  });
}

/// A [RemoteChannel] whose event stream the test feeds directly.
class _FakeChannel implements RemoteChannel {
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  void emit(Map<String, dynamic> event) => _events.add(event);

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _events.stream;

  @override
  Future<void> startDiscovery() async {}

  @override
  Future<void> stopDiscovery() async {}

  @override
  Future<void> connectToDevice(String deviceId) async {}

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> sendKeyCommand(String key) async {}

  @override
  Future<void> submitPairingCode(String code) async {}

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async => [];

  @override
  void dispose() => _events.close();
}
