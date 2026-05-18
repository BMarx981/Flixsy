import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flixsy/core/channels/samsung_connect_channel.dart';
import 'package:flixsy/core/channels/ssdp_discovery.dart';
import 'package:flixsy/core/channels/web_socket_connection.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// The Samsung channel is exercised through two injected seams: a fake
// WebSocket connector (whose sockets and requested URLs the test inspects)
// and a fake SSDP discoverer. No real network is touched.

const _deviceId =
    'uuid:samsung-1122::urn:samsung.com:device:RemoteControlReceiver:1';

SsdpResponse _samsungSsdp({String ip = '10.0.0.9'}) => SsdpResponse.parse(
  'HTTP/1.1 200 OK\r\n'
  'ST: urn:samsung.com:device:RemoteControlReceiver:1\r\n'
  'USN: $_deviceId\r\n'
  'LOCATION: http://$ip:7676/smp_2_\r\n'
  '\r\n',
)!;

/// Lets pending stream events and microtasks drain before assertions.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

SamsungConnectChannel _channel({
  _FakeConnector? connector,
  _FakeSsdpDiscoverer? discoverer,
  _CredentialStore? credentials,
  Duration pairingTimeout = const Duration(seconds: 2),
}) {
  final store = credentials ?? _CredentialStore();
  return SamsungConnectChannel(
    connector: (connector ?? _FakeConnector()).connect,
    discovery: discoverer ?? _FakeSsdpDiscoverer(),
    loadCredential: store.load,
    saveCredential: store.save,
    pairingTimeout: pairingTimeout,
  );
}

/// Builds a channel that has already discovered one Samsung device.
Future<SamsungConnectChannel> _discoveredChannel(
  _FakeConnector connector,
  _CredentialStore credentials, {
  Duration pairingTimeout = const Duration(seconds: 2),
}) async {
  final discoverer = _FakeSsdpDiscoverer();
  final channel = _channel(
    connector: connector,
    discoverer: discoverer,
    credentials: credentials,
    pairingTimeout: pairingTimeout,
  );
  final found = channel.deviceEvents.firstWhere(
    (e) => e['type'] == 'deviceFound',
  );
  discoverer.emit(_samsungSsdp());
  await found;
  return channel;
}

/// Builds a channel already connected to a Samsung device.
Future<SamsungConnectChannel> _connectedChannel(
  _FakeConnector connector,
) async {
  final channel = await _discoveredChannel(connector, _CredentialStore());
  final connecting = channel.connectToDevice(_deviceId);
  await _completeConnect(connector, token: 'TOKEN-1');
  await connecting;
  return channel;
}

/// Pushes the TV's `ms.channel.connect` so a pending connect can complete.
Future<void> _completeConnect(_FakeConnector connector, {String? token}) async {
  await _settle();
  connector.sockets.last.receive(
    jsonEncode({
      'event': 'ms.channel.connect',
      'data': {'token': ?token, 'clients': <dynamic>[]},
    }),
  );
  await _settle();
}

void main() {
  group('discovery', () {
    test('emits a deviceFound event for a Samsung SSDP hit', () async {
      final discoverer = _FakeSsdpDiscoverer();
      final channel = _channel(discoverer: discoverer);
      addTearDown(channel.dispose);

      final found = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'deviceFound',
      );
      discoverer.emit(_samsungSsdp());
      final device = (await found)['device'] as Map;

      expect(device['id'], _deviceId);
      expect(device['ipAddress'], '10.0.0.9');
      expect(device['name'], 'Samsung TV');
    });

    test('a discovery stream error surfaces as discoveryError', () async {
      final discoverer = _FakeSsdpDiscoverer();
      final channel = _channel(discoverer: discoverer);
      addTearDown(channel.dispose);

      final errored = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'discoveryError',
      );
      discoverer.emitError(const DiscoveryFailure('bind failed'));
      expect((await errored)['message'], contains('bind failed'));
    });

    test(
      'startDiscovery and stopDiscovery delegate to the discoverer',
      () async {
        final discoverer = _FakeSsdpDiscoverer();
        final channel = _channel(discoverer: discoverer);
        addTearDown(channel.dispose);

        await channel.startDiscovery();
        expect(discoverer.started, isTrue);
        await channel.stopDiscovery();
        expect(discoverer.stopped, isTrue);
      },
    );
  });

  group('connectToDevice', () {
    test('connects via wss://8002 and emits a connected event', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      final connected = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'connectionStateChanged',
      );
      final connecting = channel.connectToDevice(_deviceId);
      await _completeConnect(connector, token: 'TOKEN-1');
      await connecting;

      expect((await connected)['state'], 'connected');
      expect(connector.requestedUrls.first, startsWith('wss://10.0.0.9:8002'));
    });

    test('persists the token issued by the TV', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      final channel = await _discoveredChannel(connector, credentials);
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _completeConnect(connector, token: 'NEW-TOKEN');
      await connecting;

      expect(await credentials.load(_deviceId), 'NEW-TOKEN');
    });

    test('reuses a stored token in the connect URL', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      await credentials.save(_deviceId, 'STORED-TOKEN');
      final channel = await _discoveredChannel(connector, credentials);
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _completeConnect(connector, token: 'STORED-TOKEN');
      await connecting;

      expect(connector.requestedUrls.first, contains('token=STORED-TOKEN'));
    });

    test('falls back to ws://8001 when 8002 is unreachable', () async {
      final connector = _FakeConnector()..failingUrlParts.add(':8002');
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _completeConnect(connector);
      await connecting;

      expect(connector.requestedUrls, hasLength(2));
      expect(connector.requestedUrls.last, startsWith('ws://10.0.0.9:8001'));
    });

    test('throws ConnectionFailure for an undiscovered device', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice('nope'),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test(
      'throws ConnectionFailure when every endpoint is unreachable',
      () async {
        final connector = _FakeConnector()
          ..failingUrlParts.addAll({':8001', ':8002'});
        final channel = await _discoveredChannel(connector, _CredentialStore());
        addTearDown(channel.dispose);

        await expectLater(
          channel.connectToDevice(_deviceId),
          throwsA(isA<ConnectionFailure>()),
        );
      },
    );

    test('maps a denied pairing prompt to ConnectionFailure', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _settle();
      connector.sockets.last.receive(
        jsonEncode({'event': 'ms.channel.unauthorized'}),
      );

      await expectLater(connecting, throwsA(isA<ConnectionFailure>()));
    });

    test('times out when the TV never answers', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(
        connector,
        _CredentialStore(),
        pairingTimeout: const Duration(milliseconds: 80),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice(_deviceId),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });

  group('sendKeyCommand', () {
    test('sends a key as an ms.remote.control message', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      await channel.sendKeyCommand('HOME');

      final message = jsonDecode(connector.sockets.last.sent.single) as Map;
      expect(message['method'], 'ms.remote.control');
      final params = message['params'] as Map;
      expect(params['Cmd'], 'Click');
      expect(params['DataOfCmd'], 'KEY_HOME');
      expect(params['TypeOfRemote'], 'SendRemoteKey');
    });

    test('maps OK to KEY_ENTER and VOLUME_UP to KEY_VOLUP', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      await channel.sendKeyCommand('OK');
      await channel.sendKeyCommand('VOLUME_UP');

      final codes = connector.sockets.last.sent
          .map((s) => (jsonDecode(s) as Map)['params']['DataOfCmd'])
          .toList();
      expect(codes, ['KEY_ENTER', 'KEY_VOLUP']);
    });

    test('throws CommandFailure when not connected', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      await expectLater(
        channel.sendKeyCommand('HOME'),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('rejects an unsupported key with CommandFailure', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      await expectLater(
        channel.sendKeyCommand('WARP'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('disconnect', () {
    test(
      'emits disconnected, closes the socket, and blocks further keys',
      () async {
        final connector = _FakeConnector();
        final channel = await _connectedChannel(connector);
        addTearDown(channel.dispose);

        final disconnected = channel.deviceEvents.firstWhere(
          (e) =>
              e['type'] == 'connectionStateChanged' &&
              e['state'] == 'disconnected',
        );
        await channel.disconnect();
        await disconnected;

        expect(connector.sockets.last.closed, isTrue);
        await expectLater(
          channel.sendKeyCommand('HOME'),
          throwsA(isA<CommandFailure>()),
        );
      },
    );
  });
  group('pairing', () {
    test('emits pairingRequired(confirmOnTv) on a first connect', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      final paired = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'pairingRequired',
      );
      final connecting = channel.connectToDevice(_deviceId);

      final event = await paired;
      expect(event['deviceId'], _deviceId);
      expect(event['kind'], 'confirmOnTv');

      await _completeConnect(connector, token: 'T');
      await connecting;
    });

    test('does not emit pairingRequired when a token is stored', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      await credentials.save(_deviceId, 'TOK');
      final channel = await _discoveredChannel(connector, credentials);
      addTearDown(channel.dispose);

      final events = <String>[];
      channel.deviceEvents.listen((e) => events.add(e['type'] as String));

      final connecting = channel.connectToDevice(_deviceId);
      await _completeConnect(connector, token: 'TOK');
      await connecting;

      expect(events, isNot(contains('pairingRequired')));
    });

    test('submitPairingCode throws — Samsung pairs on the TV', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      await expectLater(
        channel.submitPairingCode('123456'),
        throwsA(isA<ConnectFailure>()),
      );
    });
  });
}

/// Hands out [_FakeWebSocket]s and records every URL a connect was attempted
/// against.
class _FakeConnector {
  final List<String> requestedUrls = [];
  final List<_FakeWebSocket> sockets = [];

  /// URL substrings whose connection attempts should fail.
  final Set<String> failingUrlParts = {};

  Future<WebSocketConnection> connect(String url) async {
    requestedUrls.add(url);
    if (failingUrlParts.any(url.contains)) {
      throw const SocketException('connection refused');
    }
    final socket = _FakeWebSocket();
    sockets.add(socket);
    return socket;
  }
}

/// In-memory [WebSocketConnection] the test feeds and inspects directly.
class _FakeWebSocket implements WebSocketConnection {
  final StreamController<String> _incoming = StreamController<String>();

  /// Every frame sent by the channel, in order.
  final List<String> sent = [];
  bool closed = false;

  @override
  Stream<String> get messages => _incoming.stream;

  @override
  void send(String message) => sent.add(message);

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  /// Pushes an incoming frame to the channel listening on this socket.
  void receive(String message) {
    if (!_incoming.isClosed) _incoming.add(message);
  }
}

/// [SsdpDiscoverer] whose response stream the test feeds directly.
class _FakeSsdpDiscoverer implements SsdpDiscoverer {
  final StreamController<SsdpResponse> _controller =
      StreamController<SsdpResponse>.broadcast();

  bool started = false;
  bool stopped = false;
  bool disposed = false;

  void emit(SsdpResponse response) => _controller.add(response);

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

/// In-memory stand-in for the credential callbacks backed by PreferencesDao.
class _CredentialStore {
  final Map<String, String> _store = {};

  Future<String?> load(String deviceId) async => _store[deviceId];

  Future<void> save(String deviceId, String credential) async =>
      _store[deviceId] = credential;
}
