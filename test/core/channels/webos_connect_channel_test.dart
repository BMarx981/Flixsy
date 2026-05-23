import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flixsy/core/channels/ssdp_discovery.dart';
import 'package:flixsy/core/channels/web_socket_connection.dart';
import 'package:flixsy/core/channels/webos_connect_channel.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// The webOS channel is exercised through two injected seams: a fake WebSocket
// connector whose sockets the test drives directly, and a fake SSDP
// discoverer. No real network is touched.

const _deviceId =
    'uuid:webos-aabbccdd::urn:lge-com:service:webos-second-screen:1';
const _pointerPath = 'ws://10.0.0.5:3000/resources/pointer';

SsdpResponse _webosSsdp({String ip = '10.0.0.5'}) => SsdpResponse.parse(
  'HTTP/1.1 200 OK\r\n'
  'ST: urn:lge-com:service:webos-second-screen:1\r\n'
  'USN: $_deviceId\r\n'
  'LOCATION: http://$ip:1976/\r\n'
  '\r\n',
)!;

/// Lets pending stream events and microtasks drain before assertions.
Future<void> _settle() => Future<void>.delayed(Duration.zero);

WebosConnectChannel _channel({
  _FakeConnector? connector,
  _FakeSsdpDiscoverer? discoverer,
  _CredentialStore? credentials,
  Duration pairingTimeout = const Duration(seconds: 2),
}) {
  final store = credentials ?? _CredentialStore();
  return WebosConnectChannel(
    connector: (connector ?? _FakeConnector()).connect,
    discovery: discoverer ?? _FakeSsdpDiscoverer(),
    loadCredential: store.load,
    saveCredential: store.save,
    pairingTimeout: pairingTimeout,
    requestTimeout: const Duration(seconds: 2),
  );
}

/// Builds a channel that has already discovered one webOS device.
Future<WebosConnectChannel> _discoveredChannel(
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
  discoverer.emit(_webosSsdp());
  await found;
  return channel;
}

/// Builds a channel already connected to a webOS device.
Future<WebosConnectChannel> _connectedChannel(_FakeConnector connector) async {
  final channel = await _discoveredChannel(connector, _CredentialStore());
  final connecting = channel.connectToDevice(_deviceId);
  await _completeHandshake(connector);
  await connecting;
  return channel;
}

/// Drives the SSAP register + pointer-socket handshake so a pending
/// connectToDevice() future can complete.
Future<void> _completeHandshake(
  _FakeConnector connector, {
  String clientKey = 'KEY-1',
}) async {
  await _settle();
  final main = connector.sockets[0];
  main.receive(
    jsonEncode({
      'type': 'registered',
      'id': 'register_0',
      'payload': {'client-key': clientKey},
    }),
  );
  await _settle();
  final pointerRequest = jsonDecode(main.sent.last) as Map;
  main.receive(
    jsonEncode({
      'type': 'response',
      'id': pointerRequest['id'],
      'payload': {'socketPath': _pointerPath},
    }),
  );
  await _settle();
}

void main() {
  group('discovery', () {
    test('emits a deviceFound event for a webOS SSDP hit', () async {
      final discoverer = _FakeSsdpDiscoverer();
      final channel = _channel(discoverer: discoverer);
      addTearDown(channel.dispose);

      final found = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'deviceFound',
      );
      discoverer.emit(_webosSsdp());
      final device = (await found)['device'] as Map;

      expect(device['id'], _deviceId);
      expect(device['ipAddress'], '10.0.0.5');
      expect(device['name'], 'LG webOS TV');
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
    test(
      'registers, pairs, opens the pointer socket, emits connected',
      () async {
        final connector = _FakeConnector();
        final channel = await _discoveredChannel(connector, _CredentialStore());
        addTearDown(channel.dispose);

        final connected = channel.deviceEvents.firstWhere(
          (e) => e['type'] == 'connectionStateChanged',
        );
        final connecting = channel.connectToDevice(_deviceId);
        await _completeHandshake(connector);
        await connecting;

        expect((await connected)['state'], 'connected');
        // One socket for SSAP, one for the pointer input.
        expect(connector.sockets, hasLength(2));
        final register = jsonDecode(connector.sockets[0].sent.first) as Map;
        expect(register['type'], 'register');
        expect((register['payload'] as Map)['manifest'], isNotNull);
      },
    );

    test('persists the client-key issued by the TV', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      final channel = await _discoveredChannel(connector, credentials);
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _completeHandshake(connector, clientKey: 'KEY-XYZ');
      await connecting;

      expect(await credentials.load(_deviceId), 'KEY-XYZ');
    });

    test('reuses a stored client-key in the register payload', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      await credentials.save(_deviceId, 'STORED-KEY');
      final channel = await _discoveredChannel(connector, credentials);
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _completeHandshake(connector, clientKey: 'STORED-KEY');
      await connecting;

      final register = jsonDecode(connector.sockets[0].sent.first) as Map;
      expect((register['payload'] as Map)['client-key'], 'STORED-KEY');
    });

    test('throws ConnectionFailure for an undiscovered device', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice('nope'),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('maps a socket connection failure to ConnectionFailure', () async {
      final connector = _FakeConnector()..failConnections = true;
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice(_deviceId),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('maps a register error response to ConnectionFailure', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _settle();
      connector.sockets[0].receive(
        jsonEncode({
          'type': 'error',
          'id': 'register_0',
          'error': '403 user rejected pairing',
        }),
      );

      await expectLater(connecting, throwsA(isA<ConnectionFailure>()));
    });

    test('times out pairing when the TV never responds', () async {
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
    test('sends a D-pad key as a pointer-socket button frame', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      await channel.sendKeyCommand('UP');

      expect(connector.pointerSocket.sent.single, 'type:button\nname:UP\n\n');
    });

    test('maps OK to ENTER and VOLUME_UP to VOLUMEUP', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      await channel.sendKeyCommand('OK');
      await channel.sendKeyCommand('VOLUME_UP');

      expect(connector.pointerSocket.sent, [
        'type:button\nname:ENTER\n\n',
        'type:button\nname:VOLUMEUP\n\n',
      ]);
    });

    test('throws CommandFailure when not connected', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      await expectLater(
        channel.sendKeyCommand('UP'),
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

  group('pointerControl', () {
    test('is null until the pointer socket is open', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      expect(channel.pointerControl, isNull);
    });

    test('exposes the channel once connected', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      expect(channel.pointerControl, same(channel));
    });

    test('sendPointerMove writes a webOS move frame', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final pointer = channel.pointerControl!;

      await pointer.sendPointerMove(12.4, -7.6);

      // Last entry on the pointer socket is the move frame — first is the
      // dummy receiver from the handshake.
      expect(
        connector.pointerSocket.sent.last,
        'type:move\ndx:12\ndy:-8\ndown:0\n\n',
      );
    });

    test('sendPointerClick writes a webOS click frame', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final pointer = channel.pointerControl!;

      await pointer.sendPointerClick();

      expect(connector.pointerSocket.sent.last, 'type:click\n\n');
    });

    test('throws CommandFailure after disconnect', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final pointer = channel.pointerControl!;

      await channel.disconnect();

      await expectLater(
        pointer.sendPointerMove(1, 1),
        throwsA(isA<CommandFailure>()),
      );
      await expectLater(
        pointer.sendPointerClick(),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('disconnect', () {
    test(
      'emits disconnected, closes sockets, and blocks further keys',
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

        expect(connector.sockets[0].closed, isTrue);
        expect(connector.pointerSocket.closed, isTrue);
        await expectLater(
          channel.sendKeyCommand('UP'),
          throwsA(isA<CommandFailure>()),
        );
      },
    );
  });
  group('pairing', () {
    test('emits pairingRequired(confirmOnTv) while the TV prompts', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);

      final paired = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'pairingRequired',
      );
      final connecting = channel.connectToDevice(_deviceId);
      await _settle();
      // The TV shows its prompt: an interim response precedes `registered`.
      connector.sockets[0].receive(
        jsonEncode({
          'type': 'response',
          'id': 'register_0',
          'payload': {'pairingType': 'PROMPT'},
        }),
      );

      final event = await paired;
      expect(event['deviceId'], _deviceId);
      expect(event['kind'], 'confirmOnTv');

      await _completeHandshake(connector);
      await connecting;
    });

    test('does not emit pairingRequired when a stored key is reused', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      await credentials.save(_deviceId, 'STORED');
      final channel = await _discoveredChannel(connector, credentials);
      addTearDown(channel.dispose);

      final events = <String>[];
      channel.deviceEvents.listen((e) => events.add(e['type'] as String));

      final connecting = channel.connectToDevice(_deviceId);
      await _completeHandshake(connector, clientKey: 'STORED');
      await connecting;

      expect(events, isNot(contains('pairingRequired')));
    });

    test('submitPairingCode throws — webOS pairs on the TV', () async {
      final channel = _channel();
      addTearDown(channel.dispose);

      await expectLater(
        channel.submitPairingCode('123456'),
        throwsA(isA<ConnectFailure>()),
      );
    });
  });

  group('textInput', () {
    test('is null until connected, then routes to this', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(connector, _CredentialStore());
      addTearDown(channel.dispose);
      expect(channel.textInput, isNull);

      final connecting = channel.connectToDevice(_deviceId);
      await _completeHandshake(connector);
      await connecting;

      expect(channel.textInput, same(channel));

      await channel.disconnect();
      expect(channel.textInput, isNull);
    });

    test('sendText issues an SSAP insertText with replace:false', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final main = connector.sockets[0];
      main.sent.clear();

      final pending = channel.textInput!.sendText('hello world');
      await _settle();
      final request = jsonDecode(main.sent.single) as Map;
      expect(request['type'], 'request');
      expect(request['uri'], 'ssap://com.webos.service.ime/insertText');
      expect(request['payload'], {'text': 'hello world', 'replace': false});

      // TV acks; the future resolves.
      main.receive(jsonEncode({
        'type': 'response',
        'id': request['id'],
        'payload': {'returnValue': true},
      }));
      await pending;
    });

    test('sendText on an empty string is a no-op (no frame)', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final main = connector.sockets[0];
      main.sent.clear();

      await channel.textInput!.sendText('');

      expect(main.sent, isEmpty);
    });

    test('sendBackspace issues deleteCharacters with count:1', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final main = connector.sockets[0];
      main.sent.clear();

      final pending = channel.textInput!.sendBackspace();
      await _settle();
      final request = jsonDecode(main.sent.single) as Map;
      expect(
        request['uri'],
        'ssap://com.webos.service.ime/deleteCharacters',
      );
      expect(request['payload'], {'count': 1});

      main.receive(jsonEncode({
        'type': 'response',
        'id': request['id'],
        'payload': {'returnValue': true},
      }));
      await pending;
    });

    test('submit issues sendEnterKey with no payload', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final main = connector.sockets[0];
      main.sent.clear();

      final pending = channel.textInput!.submit();
      await _settle();
      final request = jsonDecode(main.sent.single) as Map;
      expect(request['uri'], 'ssap://com.webos.service.ime/sendEnterKey');
      expect(request.containsKey('payload'), isFalse);

      main.receive(jsonEncode({
        'type': 'response',
        'id': request['id'],
        'payload': {'returnValue': true},
      }));
      await pending;
    });

    test('clear issues insertText with empty text and replace:true', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final main = connector.sockets[0];
      main.sent.clear();

      final pending = channel.textInput!.clear(knownLength: 42);
      await _settle();
      final request = jsonDecode(main.sent.single) as Map;
      expect(request['uri'], 'ssap://com.webos.service.ime/insertText');
      // knownLength is ignored on webOS — `replace:true` does the wipe.
      expect(request['payload'], {'text': '', 'replace': true});

      main.receive(jsonEncode({
        'type': 'response',
        'id': request['id'],
        'payload': {'returnValue': true},
      }));
      await pending;
    });

    test(
      'a TV error response surfaces as CommandFailure, not ConnectionFailure',
      () async {
        // The IME service returns an `error` SSAP type when no field is
        // focused. _sendRequest maps that to ConnectionFailure (handshake
        // semantics); _imeRequest re-throws as CommandFailure so the UI
        // treats it as a post-connect command failure.
        final connector = _FakeConnector();
        final channel = await _connectedChannel(connector);
        addTearDown(channel.dispose);
        final main = connector.sockets[0];
        main.sent.clear();

        final pending = channel.textInput!.sendText('hi');
        await _settle();
        final request = jsonDecode(main.sent.single) as Map;
        main.receive(jsonEncode({
          'type': 'error',
          'id': request['id'],
          'error': 'no input field focused',
        }));

        await expectLater(pending, throwsA(isA<CommandFailure>()));
      },
    );

    test('sendText throws CommandFailure when not connected', () async {
      final channel = _channel();
      addTearDown(channel.dispose);
      // No connection at all — the public method must reject rather than
      // try to dereference a null socket.
      await expectLater(
        channel.sendText('x'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });
}

/// Hands out [_FakeWebSocket]s and records every socket opened.
class _FakeConnector {
  final List<_FakeWebSocket> sockets = [];
  bool failConnections = false;

  Future<WebSocketConnection> connect(String url) async {
    if (failConnections) throw const SocketException('connection refused');
    final socket = _FakeWebSocket();
    sockets.add(socket);
    return socket;
  }

  /// The pointer-input socket — the second socket opened during a connect.
  _FakeWebSocket get pointerSocket => sockets[1];
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
