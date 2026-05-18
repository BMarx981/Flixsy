import 'dart:async';

import 'package:flixsy/core/channels/composite_remote_channel.dart';
import 'package:flixsy/core/channels/multicast_lock.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// CompositeRemoteChannel is exercised against fake sub-channels: their event
// streams are driven directly and their calls recorded, so routing and
// fan-out are verified without any real transport.

Map<String, dynamic> _device(String id) => {
  'id': id,
  'name': id,
  'ipAddress': '',
  'modelName': '',
};

/// Lets pending stream events and microtasks drain before assertions.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  group('discovery fan-out', () {
    test('startDiscovery starts every sub-channel', () async {
      final a = _FakeRemoteChannel();
      final b = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([a, b]);
      addTearDown(composite.dispose);

      await composite.startDiscovery();

      expect(a.startCount, 1);
      expect(b.startCount, 1);
    });

    test('stopDiscovery stops every sub-channel', () async {
      final a = _FakeRemoteChannel();
      final b = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([a, b]);
      addTearDown(composite.dispose);

      await composite.stopDiscovery();

      expect(a.stopCount, 1);
      expect(b.stopCount, 1);
    });

    test('merges device events from every sub-channel', () async {
      final a = _FakeRemoteChannel();
      final b = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([a, b]);
      addTearDown(composite.dispose);

      final ids = <String>[];
      composite.deviceEvents
          .where((e) => e['type'] == 'deviceFound')
          .listen((e) => ids.add((e['device'] as Map)['id'] as String));

      a.emitDeviceFound('roku-1');
      b.emitDeviceFound('lg-1');
      await _settle();

      expect(ids, containsAll(['roku-1', 'lg-1']));
    });

    test(
      'a partial discovery failure emits discoveryError, does not throw',
      () async {
        final ok = _FakeRemoteChannel();
        final failing = _FakeRemoteChannel()
          ..startFailure = const DiscoveryFailure('bind failed');
        final composite = CompositeRemoteChannel([ok, failing]);
        addTearDown(composite.dispose);

        final errored = composite.deviceEvents.firstWhere(
          (e) => e['type'] == 'discoveryError',
        );

        await composite.startDiscovery(); // must not throw
        expect((await errored)['message'], contains('bind failed'));
        expect(ok.startCount, 1);
      },
    );

    test('throws DiscoveryFailure when every sub-channel fails', () async {
      final a = _FakeRemoteChannel()
        ..startFailure = const DiscoveryFailure('a down');
      final b = _FakeRemoteChannel()
        ..startFailure = const DiscoveryFailure('b down');
      final composite = CompositeRemoteChannel([a, b]);
      addTearDown(composite.dispose);

      await expectLater(
        composite.startDiscovery(),
        throwsA(isA<DiscoveryFailure>()),
      );
    });

    test(
      'getDiscoveredDevices concatenates every sub-channel snapshot',
      () async {
        final a = _FakeRemoteChannel()..discovered = [_device('roku-1')];
        final b = _FakeRemoteChannel()
          ..discovered = [_device('lg-1'), _device('lg-2')];
        final composite = CompositeRemoteChannel([a, b]);
        addTearDown(composite.dispose);

        final devices = await composite.getDiscoveredDevices();

        expect(devices, hasLength(3));
        expect(
          devices.map((d) => d['id']),
          containsAll(['roku-1', 'lg-1', 'lg-2']),
        );
      },
    );
  });

  group('routing by owning channel', () {
    test(
      'connectToDevice routes to the channel that found the device',
      () async {
        final roku = _FakeRemoteChannel();
        final lg = _FakeRemoteChannel();
        final composite = CompositeRemoteChannel([roku, lg]);
        addTearDown(composite.dispose);

        lg.emitDeviceFound('lg-1');
        await _settle();
        await composite.connectToDevice('lg-1');

        expect(lg.connectedDeviceId, 'lg-1');
        expect(roku.connectedDeviceId, isNull);
      },
    );

    test(
      'connectToDevice throws ConnectionFailure for an unknown device',
      () async {
        final composite = CompositeRemoteChannel([_FakeRemoteChannel()]);
        addTearDown(composite.dispose);

        await expectLater(
          composite.connectToDevice('ghost'),
          throwsA(isA<ConnectionFailure>()),
        );
      },
    );

    test('sendKeyCommand routes to the connected channel only', () async {
      final roku = _FakeRemoteChannel();
      final lg = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([roku, lg]);
      addTearDown(composite.dispose);

      roku.emitDeviceFound('roku-1');
      await _settle();
      await composite.connectToDevice('roku-1');
      await composite.sendKeyCommand('HOME');

      expect(roku.sentKeys, ['HOME']);
      expect(lg.sentKeys, isEmpty);
    });

    test(
      'sendKeyCommand throws CommandFailure when nothing is connected',
      () async {
        final composite = CompositeRemoteChannel([_FakeRemoteChannel()]);
        addTearDown(composite.dispose);

        await expectLater(
          composite.sendKeyCommand('HOME'),
          throwsA(isA<CommandFailure>()),
        );
      },
    );

    test('connecting to a second transport disconnects the first', () async {
      final roku = _FakeRemoteChannel();
      final lg = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([roku, lg]);
      addTearDown(composite.dispose);

      roku.emitDeviceFound('roku-1');
      lg.emitDeviceFound('lg-1');
      await _settle();

      await composite.connectToDevice('roku-1');
      await composite.connectToDevice('lg-1');

      expect(roku.disconnectCount, 1);
      expect(lg.connectedDeviceId, 'lg-1');
    });

    test('disconnect delegates to the active channel only', () async {
      final roku = _FakeRemoteChannel();
      final lg = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([roku, lg]);
      addTearDown(composite.dispose);

      roku.emitDeviceFound('roku-1');
      await _settle();
      await composite.connectToDevice('roku-1');
      await composite.disconnect();

      expect(roku.disconnectCount, 1);
      expect(lg.disconnectCount, 0);
    });
  });

  group('dispose', () {
    test('disposes every sub-channel and closes the event stream', () async {
      final a = _FakeRemoteChannel();
      final b = _FakeRemoteChannel();
      final composite = CompositeRemoteChannel([a, b]);

      composite.dispose();

      expect(a.disposed, isTrue);
      expect(b.disposed, isTrue);
      await expectLater(composite.deviceEvents, emitsDone);
    });
  });
  group('pairing', () {
    test('submitPairingCode routes to the channel currently pairing', () async {
      final roku = _FakeRemoteChannel();
      final lg = _FakeRemoteChannel()..connectGate = Completer<void>();
      final composite = CompositeRemoteChannel([roku, lg]);
      addTearDown(composite.dispose);

      lg.emitDeviceFound('lg-1');
      await _settle();
      final connecting = composite.connectToDevice('lg-1');
      await _settle();

      await composite.submitPairingCode('123456');
      expect(lg.submittedCodes, ['123456']);
      expect(roku.submittedCodes, isEmpty);

      lg.connectGate!.complete();
      await connecting;
    });

    test('submitPairingCode throws when no pairing is in progress', () async {
      final composite = CompositeRemoteChannel([_FakeRemoteChannel()]);
      addTearDown(composite.dispose);

      await expectLater(
        composite.submitPairingCode('123'),
        throwsA(isA<ConnectFailure>()),
      );
    });
  });

  group('multicast lock', () {
    test('startDiscovery acquires the lock', () async {
      final lock = _FakeMulticastLock();
      final composite = CompositeRemoteChannel([
        _FakeRemoteChannel(),
      ], multicastLock: lock);
      addTearDown(composite.dispose);

      await composite.startDiscovery();

      expect(lock.acquireCount, 1);
      expect(lock.releaseCount, 0);
    });

    test('stopDiscovery releases the lock', () async {
      final lock = _FakeMulticastLock();
      final composite = CompositeRemoteChannel([
        _FakeRemoteChannel(),
      ], multicastLock: lock);
      addTearDown(composite.dispose);

      await composite.startDiscovery();
      await composite.stopDiscovery();

      expect(lock.acquireCount, 1);
      expect(lock.releaseCount, 1);
    });

    test('a repeated startDiscovery does not stack a second hold', () async {
      final lock = _FakeMulticastLock();
      final composite = CompositeRemoteChannel([
        _FakeRemoteChannel(),
      ], multicastLock: lock);
      addTearDown(composite.dispose);

      await composite.startDiscovery();
      await composite.startDiscovery();

      expect(lock.acquireCount, 1);
    });

    test(
      'the lock is released when every sub-channel fails to start',
      () async {
        final lock = _FakeMulticastLock();
        final composite = CompositeRemoteChannel([
          _FakeRemoteChannel()..startFailure = const DiscoveryFailure('down'),
        ], multicastLock: lock);
        addTearDown(composite.dispose);

        await expectLater(
          composite.startDiscovery(),
          throwsA(isA<DiscoveryFailure>()),
        );

        expect(lock.acquireCount, 1);
        expect(lock.releaseCount, 1);
      },
    );

    test('dispose releases a still-held lock', () async {
      final lock = _FakeMulticastLock();
      final composite = CompositeRemoteChannel([
        _FakeRemoteChannel(),
      ], multicastLock: lock);

      await composite.startDiscovery();
      composite.dispose();

      expect(lock.releaseCount, 1);
    });
  });
}

/// A scriptable [RemoteChannel] that records calls and lets the test feed its
/// [deviceEvents] stream directly.
class _FakeRemoteChannel implements RemoteChannel {
  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  int startCount = 0;
  int stopCount = 0;
  int disconnectCount = 0;
  bool disposed = false;
  String? connectedDeviceId;
  final List<String> sentKeys = [];
  List<Map<String, dynamic>> discovered = [];

  /// When set, [startDiscovery] throws it instead of succeeding.
  ConnectFailure? startFailure;

  /// When set, [connectToDevice] awaits it — keeping a connect in flight so
  /// the composite still has a pairing channel.
  Completer<void>? connectGate;

  /// Every code passed to [submitPairingCode].
  final List<String> submittedCodes = [];

  void emitDeviceFound(String id) =>
      _events.add({'type': 'deviceFound', 'device': _device(id)});

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _events.stream;

  @override
  Future<void> startDiscovery() async {
    if (startFailure != null) throw startFailure!;
    startCount++;
  }

  @override
  Future<void> stopDiscovery() async => stopCount++;

  @override
  Future<void> connectToDevice(String deviceId) async {
    connectedDeviceId = deviceId;
    if (connectGate != null) await connectGate!.future;
  }

  @override
  Future<void> submitPairingCode(String code) async => submittedCodes.add(code);

  @override
  Future<void> disconnect() async {
    disconnectCount++;
    connectedDeviceId = null;
  }

  @override
  Future<void> sendKeyCommand(String key) async => sentKeys.add(key);

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async => discovered;

  @override
  void dispose() {
    disposed = true;
    _events.close();
  }
}

/// A [MulticastLock] that just counts balanced acquire / release calls.
class _FakeMulticastLock implements MulticastLock {
  int acquireCount = 0;
  int releaseCount = 0;

  @override
  Future<void> acquire() async => acquireCount++;

  @override
  Future<void> release() async => releaseCount++;
}
