import 'dart:async';

import 'package:flutter/foundation.dart';

import 'remote_channel.dart';

/// In-memory [RemoteChannel] that simulates TVs on the local network, so the
/// app can be run in a simulator/emulator with no native side and no real
/// device.
///
/// Wire it in by overriding `connectChannelProvider` (see `main.dart`, gated
/// behind the `FAKE_TV` dart-define).
class FakeConnectChannel implements RemoteChannel {
  final _eventController = StreamController<Map<String, dynamic>>.broadcast();

  /// The fake TVs "discovered" on the network. Shape matches what
  /// [TvDevice.fromMap] expects.
  static const _fakeDevices = <Map<String, dynamic>>[
    {
      'id': 'fake-living-room',
      'name': 'Living Room TV',
      'ipAddress': '192.168.1.42',
      'modelName': 'Flixsy Simulator (LG webOS)',
    },
    {
      'id': 'fake-bedroom',
      'name': 'Bedroom TV',
      'ipAddress': '192.168.1.57',
      'modelName': 'Flixsy Simulator (Samsung Tizen)',
    },
  ];

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _eventController.stream;

  @override
  Future<void> startDiscovery() async {
    debugPrint('[FakeConnectChannel] startDiscovery');
    // Trickle the devices in with a staggered delay, the way a real
    // discovery sweep would surface results one at a time.
    for (var i = 0; i < _fakeDevices.length; i++) {
      Future.delayed(Duration(milliseconds: 700 * (i + 1)), () {
        if (_eventController.isClosed) return;
        _eventController.add({
          'type': 'deviceFound',
          'device': _fakeDevices[i],
        });
      });
    }
  }

  @override
  Future<void> stopDiscovery() async {
    debugPrint('[FakeConnectChannel] stopDiscovery');
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    debugPrint('[FakeConnectChannel] connectToDevice $deviceId');
    await Future<void>.delayed(const Duration(milliseconds: 600));
  }

  @override
  Future<void> disconnect() async {
    debugPrint('[FakeConnectChannel] disconnect');
  }

  @override
  Future<void> sendKeyCommand(String key) async {
    debugPrint('[FakeConnectChannel] sendKeyCommand $key');
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  @override
  Future<void> submitPairingCode(String code) async {
    debugPrint('[FakeConnectChannel] submitPairingCode $code');
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async {
    return _fakeDevices.map(Map<String, dynamic>.from).toList();
  }

  /// Closes the event stream. Wire this into the overriding provider's
  /// `ref.onDispose`.
  @override
  void dispose() {
    _eventController.close();
  }
}
