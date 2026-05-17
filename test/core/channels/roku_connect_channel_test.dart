import 'dart:async';

import 'package:flixsy/core/channels/roku_connect_channel.dart';
import 'package:flixsy/core/channels/ssdp_discovery.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// The Roku channel is exercised end-to-end through two injected seams: a fake
// HTTP client (no live ECP server) and a fake SSDP discoverer whose response
// stream the test drives directly. The live UDP socket path is covered by
// integration testing — see ssdp_discovery_test.dart.

const _deviceId = 'uuid:roku:ecp:P0A070000007';

const _deviceInfoXml = '''
<device-info>
  <udn>015e5108-9000-1046-8035-b0a737964dfb</udn>
  <serial-number>P0A070000007</serial-number>
  <model-name>3810X</model-name>
  <friendly-model-name>Roku Streaming Stick+</friendly-model-name>
  <user-device-name>Living Room Roku</user-device-name>
  <default-device-name>Roku Streaming Stick+ - P0A070000007</default-device-name>
</device-info>
''';

/// One SSDP `M-SEARCH` hit from a Roku at [ip].
SsdpResponse _rokuSsdp({String ip = '192.168.1.7'}) => SsdpResponse.parse(
  'HTTP/1.1 200 OK\r\n'
  'ST: roku:ecp\r\n'
  'USN: $_deviceId\r\n'
  'LOCATION: http://$ip:8060/\r\n'
  '\r\n',
)!;

/// HTTP client that serves device-info XML and accepts every keypress.
_FakeRokuHttpClient _okHttp() => _FakeRokuHttpClient((method, url) {
  if (url.path == '/query/device-info') {
    return const RokuHttpResponse(statusCode: 200, body: _deviceInfoXml);
  }
  return const RokuHttpResponse(statusCode: 200);
});

/// Builds a channel with one Roku already discovered and registered.
Future<RokuConnectChannel> _channelWithDevice(
  _FakeRokuHttpClient http,
  _FakeSsdpDiscoverer discoverer,
) async {
  final channel = RokuConnectChannel(httpClient: http, discovery: discoverer);
  final found = channel.deviceEvents.firstWhere(
    (e) => e['type'] == 'deviceFound',
  );
  discoverer.emit(_rokuSsdp());
  await found;
  return channel;
}

void main() {
  group('discovery', () {
    test('fetches device-info and emits a named deviceFound event', () async {
      final http = _okHttp();
      final discoverer = _FakeSsdpDiscoverer();
      final channel = RokuConnectChannel(
        httpClient: http,
        discovery: discoverer,
      );
      addTearDown(channel.dispose);

      final found = expectLater(
        channel.deviceEvents,
        emits(
          predicate<Map<String, dynamic>>((event) {
            final device = event['device'] as Map;
            return event['type'] == 'deviceFound' &&
                device['id'] == _deviceId &&
                device['name'] == 'Living Room Roku' &&
                device['modelName'] == 'Roku Streaming Stick+' &&
                device['ipAddress'] == '192.168.1.7';
          }),
        ),
      );
      discoverer.emit(_rokuSsdp());
      await found;
    });

    test('falls back to defaults when device-info is unavailable', () async {
      final http = _FakeRokuHttpClient(
        (method, url) => const RokuHttpResponse(statusCode: 500),
      );
      final discoverer = _FakeSsdpDiscoverer();
      final channel = RokuConnectChannel(
        httpClient: http,
        discovery: discoverer,
      );
      addTearDown(channel.dispose);

      final found = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'deviceFound',
      );
      discoverer.emit(_rokuSsdp());
      final device = (await found)['device'] as Map;
      expect(device['name'], 'Roku');
      expect(device['modelName'], '');
      expect(device['ipAddress'], '192.168.1.7');
    });

    test(
      'a discovery stream error surfaces as a discoveryError event',
      () async {
        final discoverer = _FakeSsdpDiscoverer();
        final channel = RokuConnectChannel(
          httpClient: _okHttp(),
          discovery: discoverer,
        );
        addTearDown(channel.dispose);

        final errored = channel.deviceEvents.firstWhere(
          (e) => e['type'] == 'discoveryError',
        );
        discoverer.emitError(const DiscoveryFailure('socket bind failed'));
        expect((await errored)['message'], contains('socket bind failed'));
      },
    );

    test(
      'startDiscovery and stopDiscovery delegate to the discoverer',
      () async {
        final discoverer = _FakeSsdpDiscoverer();
        final channel = RokuConnectChannel(
          httpClient: _okHttp(),
          discovery: discoverer,
        );
        addTearDown(channel.dispose);

        await channel.startDiscovery();
        expect(discoverer.started, isTrue);
        await channel.stopDiscovery();
        expect(discoverer.stopped, isTrue);
      },
    );

    test(
      'getDiscoveredDevices returns a snapshot of discovered devices',
      () async {
        final http = _okHttp();
        final discoverer = _FakeSsdpDiscoverer();
        final channel = await _channelWithDevice(http, discoverer);
        addTearDown(channel.dispose);

        final devices = await channel.getDiscoveredDevices();
        expect(devices, hasLength(1));
        expect(devices.first['id'], _deviceId);
        expect(devices.first['name'], 'Living Room Roku');
      },
    );
  });

  group('connectToDevice', () {
    test('does a liveness check and emits a connected event', () async {
      final http = _okHttp();
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);

      final connected = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'connectionStateChanged',
      );
      await channel.connectToDevice(_deviceId);

      expect((await connected)['state'], 'connected');
      expect(http.calls.last.method, 'GET');
      expect(http.calls.last.url.path, '/query/device-info');
    });

    test('throws ConnectionFailure for an undiscovered device id', () async {
      final channel = RokuConnectChannel(
        httpClient: _okHttp(),
        discovery: _FakeSsdpDiscoverer(),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice('nope'),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('maps a transport error to ConnectionFailure', () async {
      var deviceInfoCalls = 0;
      final http = _FakeRokuHttpClient((method, url) {
        if (url.path == '/query/device-info') {
          deviceInfoCalls++;
          if (deviceInfoCalls == 1) {
            return const RokuHttpResponse(
              statusCode: 200,
              body: _deviceInfoXml,
            );
          }
          throw Exception('host unreachable');
        }
        return const RokuHttpResponse(statusCode: 200);
      });
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice(_deviceId),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('maps a non-2xx liveness response to ConnectionFailure', () async {
      var deviceInfoCalls = 0;
      final http = _FakeRokuHttpClient((method, url) {
        if (url.path == '/query/device-info') {
          deviceInfoCalls++;
          return deviceInfoCalls == 1
              ? const RokuHttpResponse(statusCode: 200, body: _deviceInfoXml)
              : const RokuHttpResponse(statusCode: 403);
        }
        return const RokuHttpResponse(statusCode: 200);
      });
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice(_deviceId),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });

  group('sendKeyCommand', () {
    test('maps a generic key to a Roku ECP keypress POST', () async {
      final http = _okHttp();
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);
      await channel.connectToDevice(_deviceId);

      await channel.sendKeyCommand('UP');

      final call = http.calls.last;
      expect(call.method, 'POST');
      expect(call.url.path, '/keypress/Up');
      expect(call.url.host, '192.168.1.7');
      expect(call.url.port, 8060);
    });

    test('throws CommandFailure when not connected', () async {
      final channel = RokuConnectChannel(
        httpClient: _okHttp(),
        discovery: _FakeSsdpDiscoverer(),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.sendKeyCommand('UP'),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('rejects an unsupported key with CommandFailure', () async {
      final http = _okHttp();
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);
      await channel.connectToDevice(_deviceId);

      await expectLater(
        channel.sendKeyCommand('WARP_SPEED'),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('surfaces a non-2xx keypress response as CommandFailure', () async {
      final http = _FakeRokuHttpClient((method, url) {
        if (url.path == '/query/device-info') {
          return const RokuHttpResponse(statusCode: 200, body: _deviceInfoXml);
        }
        return const RokuHttpResponse(statusCode: 500);
      });
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);
      await channel.connectToDevice(_deviceId);

      await expectLater(
        channel.sendKeyCommand('HOME'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('disconnect', () {
    test('emits a disconnected event and blocks further keys', () async {
      final http = _okHttp();
      final discoverer = _FakeSsdpDiscoverer();
      final channel = await _channelWithDevice(http, discoverer);
      addTearDown(channel.dispose);
      await channel.connectToDevice(_deviceId);

      final disconnected = channel.deviceEvents.firstWhere(
        (e) =>
            e['type'] == 'connectionStateChanged' &&
            e['state'] == 'disconnected',
      );
      await channel.disconnect();
      await disconnected;

      await expectLater(
        channel.sendKeyCommand('UP'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('dispose', () {
    test('tears down the HTTP client, discoverer, and event stream', () async {
      final http = _okHttp();
      final discoverer = _FakeSsdpDiscoverer();
      final channel = RokuConnectChannel(
        httpClient: http,
        discovery: discoverer,
      );

      channel.dispose();

      expect(http.closed, isTrue);
      expect(discoverer.disposed, isTrue);
      await expectLater(channel.deviceEvents, emitsDone);
    });
  });
}

/// [RokuHttpClient] whose every request is answered by an injected handler.
class _FakeRokuHttpClient implements RokuHttpClient {
  _FakeRokuHttpClient(this._handler);

  final FutureOr<RokuHttpResponse> Function(String method, Uri url) _handler;

  /// Every request issued, in order.
  final List<({String method, Uri url})> calls = [];
  bool closed = false;

  @override
  Future<RokuHttpResponse> send(String method, Uri url) async {
    calls.add((method: method, url: url));
    return _handler(method, url);
  }

  @override
  void close() => closed = true;
}

/// [SsdpDiscoverer] whose response stream the test feeds directly.
class _FakeSsdpDiscoverer implements SsdpDiscoverer {
  final StreamController<SsdpResponse> _controller =
      StreamController<SsdpResponse>.broadcast();

  bool started = false;
  bool stopped = false;
  bool disposed = false;

  /// Pushes a discovery hit to listeners.
  void emit(SsdpResponse response) => _controller.add(response);

  /// Pushes a discovery error to listeners.
  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<SsdpResponse> get responses => _controller.stream;

  @override
  Future<void> start() async => started = true;

  @override
  Future<void> stop() async => stopped = true;

  @override
  Future<void> dispose() async {
    disposed = true;
    await _controller.close();
  }
}
