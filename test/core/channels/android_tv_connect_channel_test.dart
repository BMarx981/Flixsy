import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flixsy/core/channels/android_tv_connect_channel.dart';
import 'package:flixsy/core/channels/android_tv_crypto.dart';
import 'package:flixsy/core/channels/mdns_discovery.dart';
import 'package:flixsy/core/channels/proto_codec.dart';
import 'package:flixsy/core/channels/proto_socket.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// The Android TV channel is exercised through four injected seams: a fake TLS
// `ProtoSocket` connector, a fake mDNS discoverer, a fake `AndroidTvCrypto`
// (no real RSA), and an in-memory credential store. No real network is used.

const String _deviceId = 'Living Room TV._androidtvremote2._tcp.local';

/// `RemoteConfigure.code1` the client requests: PING|KEY|POWER|VOLUME|APP_LINK.
const int _requestedFeatures = 1 | 2 | 32 | 64 | 512;

/// Modulus hex values the fake crypto reports for the client and TV certs.
const String _clientModulus = 'AABBCCDD11223344';
const String _serverModulus = '99887766FFEEDDCC';

MdnsService _service({int port = 6466}) => MdnsService(
  name: _deviceId,
  host: 'androidtv.local',
  port: port,
  address: '192.168.1.50',
);

/// Lets pending stream events and microtasks drain before assertions.
Future<void> _settle() async {
  for (var i = 0; i < 5; i++) {
    await Future<void>.delayed(Duration.zero);
  }
}

RsaPublicNumbers _key(String modulusHex) => RsaPublicNumbers(
  modulus: BigInt.parse(modulusHex, radix: 16),
  exponent: BigInt.from(65537),
);

/// The secret the channel will derive for a [pairingCode], computed here
/// independently so the test can both inspect the wire and forge a code whose
/// check byte matches.
Uint8List _secretFor(String pairingCode) => computePairingSecret(
  clientKey: _key(_clientModulus),
  serverKey: _key(_serverModulus),
  pairingCode: pairingCode,
);

/// A 6-hex-char pairing code whose check byte matches the derived secret for
/// the given [nonce] — what a correctly-read on-screen code looks like.
String _validCode(String nonce) {
  final secret = _secretFor('00$nonce');
  return secret[0].toRadixString(16).padLeft(2, '0') + nonce;
}

/// Builds an `OuterMessage` (pairing envelope) carrying sub-message [field].
Uint8List _outer(int field, [ProtoWriter? sub]) =>
    (ProtoWriter()
          ..writeVarint(1, 2)
          ..writeVarint(2, 200)
          ..writeMessage(field, sub ?? ProtoWriter()))
        .toBytes();

/// An `OuterMessage` with a non-OK status — a TV-side pairing rejection.
Uint8List _outerError(int status) =>
    (ProtoWriter()
          ..writeVarint(1, 2)
          ..writeVarint(2, status))
        .toBytes();

/// A `RemoteMessage.remote_configure` advertising [supportedFeatures].
Uint8List _remoteConfigure(int supportedFeatures) =>
    (ProtoWriter()
          ..writeMessage(1, ProtoWriter()..writeVarint(1, supportedFeatures)))
        .toBytes();

/// A `RemoteMessage.remote_set_active`.
Uint8List _remoteSetActive() =>
    (ProtoWriter()..writeMessage(2, ProtoWriter()..writeVarint(1, 0)))
        .toBytes();

/// A `RemoteMessage.remote_start`.
Uint8List _remoteStart() =>
    (ProtoWriter()..writeMessage(40, ProtoWriter()..writeBool(1, value: true)))
        .toBytes();

/// A `RemoteMessage.remote_ping_request` carrying [value].
Uint8List _pingRequest(int value) =>
    (ProtoWriter()..writeMessage(
          8,
          ProtoWriter()
            ..writeVarint(1, value)
            ..writeVarint(2, 7),
        ))
        .toBytes();

AndroidTvConnectChannel _channel({
  required _FakeConnector connector,
  required _FakeMdnsDiscoverer discoverer,
  _CredentialStore? credentials,
}) {
  final store = credentials ?? _CredentialStore();
  return AndroidTvConnectChannel(
    connector: connector.connect,
    discovery: discoverer,
    crypto: const _FakeCrypto(),
    loadCredential: store.load,
    saveCredential: store.save,
    pairingTimeout: const Duration(seconds: 5),
    handshakeTimeout: const Duration(seconds: 5),
  );
}

/// Builds a channel that has already discovered one Android TV.
Future<AndroidTvConnectChannel> _discoveredChannel({
  required _FakeConnector connector,
  required _FakeMdnsDiscoverer discoverer,
  _CredentialStore? credentials,
}) async {
  final channel = _channel(
    connector: connector,
    discoverer: discoverer,
    credentials: credentials,
  );
  final found = channel.deviceEvents.firstWhere(
    (e) => e['type'] == 'deviceFound',
  );
  discoverer.emit(_service());
  await found;
  return channel;
}

/// Drives the pairing exchange up to the point the TV shows its code.
Future<void> _driveToAwaitingCode(_FakeConnector connector) async {
  await _settle(); // pairing socket connected, pairing_request sent
  connector.sockets[0].receive(_outer(11)); // pairing_request_ack
  await _settle();
  connector.sockets[0].receive(_outer(20)); // options
  await _settle();
  connector.sockets[0].receive(_outer(31)); // configuration_ack
  await _settle();
}

/// Builds a channel that already has a connected remote-control socket.
/// Pre-seeds the credential store so pairing is skipped — the remote socket
/// ends up at `connector.sockets[0]`.
Future<AndroidTvConnectChannel> _connectedChannel(
  _FakeConnector connector,
) async {
  final credentials = _CredentialStore();
  await credentials.save(
    _deviceId,
    jsonEncode({'cert': 'CLIENT-CERT', 'key': 'CLIENT-KEY'}),
  );
  final channel = await _discoveredChannel(
    connector: connector,
    discoverer: _FakeMdnsDiscoverer(),
    credentials: credentials,
  );
  final connecting = channel.connectToDevice(_deviceId);
  await _settle();
  await _driveRemoteHandshake(connector, socketIndex: 0);
  await connecting;
  return channel;
}

/// Drives the remote-control handshake on the socket at [socketIndex].
Future<void> _driveRemoteHandshake(
  _FakeConnector connector, {
  int socketIndex = 1,
  int supportedFeatures = _requestedFeatures,
}) async {
  final socket = connector.sockets[socketIndex];
  socket.receive(_remoteConfigure(supportedFeatures));
  await _settle();
  socket.receive(_remoteSetActive());
  await _settle();
  socket.receive(_remoteStart());
  await _settle();
}

void main() {
  group('discovery', () {
    test('emits deviceFound for an mDNS service', () async {
      final discoverer = _FakeMdnsDiscoverer();
      final channel = _channel(
        connector: _FakeConnector(),
        discoverer: discoverer,
      );
      addTearDown(channel.dispose);

      final found = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'deviceFound',
      );
      discoverer.emit(_service());
      final event = await found;

      final device = event['device'] as Map<String, dynamic>;
      expect(device['id'], _deviceId);
      expect(device['name'], 'Living Room TV');
      expect(device['ipAddress'], '192.168.1.50');
    });

    test(
      'startDiscovery and stopDiscovery delegate to the discoverer',
      () async {
        final discoverer = _FakeMdnsDiscoverer();
        final channel = _channel(
          connector: _FakeConnector(),
          discoverer: discoverer,
        );
        addTearDown(channel.dispose);

        await channel.startDiscovery();
        await channel.stopDiscovery();
        expect(discoverer.started, isTrue);
        expect(discoverer.stopped, isTrue);
      },
    );

    test('surfaces a discovery error as a discoveryError event', () async {
      final discoverer = _FakeMdnsDiscoverer();
      final channel = _channel(
        connector: _FakeConnector(),
        discoverer: discoverer,
      );
      addTearDown(channel.dispose);

      final error = channel.deviceEvents.firstWhere(
        (e) => e['type'] == 'discoveryError',
      );
      discoverer.emitError(const DiscoveryFailure('mDNS down'));
      expect((await error)['message'], 'mDNS down');
    });

    test('getDiscoveredDevices returns discovered devices', () async {
      final discoverer = _FakeMdnsDiscoverer();
      final channel = await _discoveredChannel(
        connector: _FakeConnector(),
        discoverer: discoverer,
      );
      addTearDown(channel.dispose);

      final devices = await channel.getDiscoveredDevices();
      expect(devices, hasLength(1));
      expect(devices.single['id'], _deviceId);
    });
  });

  group('connect', () {
    test('connectToDevice rejects an unknown device', () async {
      final channel = _channel(
        connector: _FakeConnector(),
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice('nope'),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('pairs a new device, then connects on the remote port', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
        credentials: credentials,
      );
      addTearDown(channel.dispose);
      final events = <Map<String, dynamic>>[];
      channel.deviceEvents.listen(events.add);

      final connecting = channel.connectToDevice(_deviceId);
      await _driveToAwaitingCode(connector);

      expect(
        events.any(
          (e) => e['type'] == 'pairingRequired' && e['kind'] == 'enterCode',
        ),
        isTrue,
      );

      await channel.submitPairingCode(_validCode('abcd'));
      connector.sockets[0].receive(_outer(41)); // secret_ack
      await _settle();
      await _driveRemoteHandshake(connector);
      await connecting;

      expect(events.last['type'], 'connectionStateChanged');
      expect(events.last['state'], 'connected');
      // Pairing on 6467, then remote control on 6466.
      expect(connector.requests.map((r) => r.port), [6467, 6466]);
      // The certificate was persisted as the pairing credential.
      expect(await credentials.load(_deviceId), isNotNull);
    });

    test('the first wire message is a pairing_request', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      unawaited(channel.connectToDevice(_deviceId).catchError((_) {}));
      await _settle();

      final request = ProtoReader.parse(connector.sockets[0].sent.first);
      expect(request.has(10), isTrue); // pairing_request
      final inner = request.readMessage(10)!;
      expect(utf8.decode(inner.readBytes(1)!), 'atvremote');
    });

    test('sends the derived secret after submitPairingCode', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      unawaited(channel.connectToDevice(_deviceId).catchError((_) {}));
      await _driveToAwaitingCode(connector);

      final code = _validCode('beef');
      await channel.submitPairingCode(code);

      final secretMessage = ProtoReader.parse(connector.sockets[0].sent.last);
      final secret = secretMessage.readMessage(40)!; // OuterMessage.secret
      expect(secret.readBytes(1), _secretFor(code));
    });

    test('a stored credential skips pairing entirely', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      await credentials.save(
        _deviceId,
        jsonEncode({'cert': 'CLIENT-CERT', 'key': 'CLIENT-KEY'}),
      );
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
        credentials: credentials,
      );
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _settle();
      await _driveRemoteHandshake(connector, socketIndex: 0);
      await connecting;

      // Only the remote-control port was opened — no pairing socket.
      expect(connector.requests.map((r) => r.port), [6466]);
    });

    test('masks the requested features against what the TV supports', () async {
      final connector = _FakeConnector();
      final credentials = _CredentialStore();
      await credentials.save(
        _deviceId,
        jsonEncode({'cert': 'CLIENT-CERT', 'key': 'CLIENT-KEY'}),
      );
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
        credentials: credentials,
      );
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _settle();
      // TV reports only PING|KEY supported.
      connector.sockets[0].receive(_remoteConfigure(1 | 2));
      await _settle();

      final reply = ProtoReader.parse(connector.sockets[0].sent.first);
      final configure = reply.readMessage(1)!; // RemoteConfigure
      expect(configure.readInt(1), _requestedFeatures & (1 | 2)); // code1

      connector.sockets[0].receive(_remoteSetActive());
      await _settle();
      connector.sockets[0].receive(_remoteStart());
      await connecting;
    });

    test('a non-OK pairing status fails the connect', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      final connecting = channel.connectToDevice(_deviceId);
      await _settle();
      connector.sockets[0].receive(_outerError(400));

      await expectLater(connecting, throwsA(isA<ConnectionFailure>()));
    });

    test('a refused pairing connection fails the connect', () async {
      final connector = _FakeConnector()..failingPorts.add(6467);
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.connectToDevice(_deviceId),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });

  group('pairing code', () {
    test('submitPairingCode throws when no pairing is in progress', () async {
      final channel = _channel(
        connector: _FakeConnector(),
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.submitPairingCode('1a2b3c'),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('an incorrect code is rejected but pairing stays open', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      unawaited(channel.connectToDevice(_deviceId).catchError((_) {}));
      await _driveToAwaitingCode(connector);

      final secret = _secretFor('00abcd');
      final wrongCheckByte = (secret[0] ^ 0xff)
          .toRadixString(16)
          .padLeft(2, '0');
      await expectLater(
        channel.submitPairingCode('${wrongCheckByte}abcd'),
        throwsA(isA<ConnectionFailure>()),
      );

      // A correct code still works afterwards — pairing was not torn down.
      await channel.submitPairingCode(_validCode('abcd'));
      final sent = ProtoReader.parse(connector.sockets[0].sent.last);
      expect(sent.has(40), isTrue); // secret
    });

    test('a malformed code is rejected', () async {
      final connector = _FakeConnector();
      final channel = await _discoveredChannel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      unawaited(channel.connectToDevice(_deviceId).catchError((_) {}));
      await _driveToAwaitingCode(connector);

      await expectLater(
        channel.submitPairingCode('12345Z'),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });

  group('control', () {
    test('sendKeyCommand injects the mapped key code', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      final socket = connector.sockets[0];
      socket.sent.clear();
      await channel.sendKeyCommand('OK');

      final message = ProtoReader.parse(socket.sent.single);
      final inject = message.readMessage(10)!; // RemoteKeyInject
      expect(inject.readInt(1), 23); // KEYCODE_DPAD_CENTER
      expect(inject.readInt(2), 3); // RemoteDirection.SHORT
    });

    test('sendKeyCommand rejects an unsupported key', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      await expectLater(
        channel.sendKeyCommand('NONSENSE'),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('sendKeyCommand fails when not connected', () async {
      final channel = _channel(
        connector: _FakeConnector(),
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);

      await expectLater(
        channel.sendKeyCommand('HOME'),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('answers a ping request with a matching ping response', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      final socket = connector.sockets[0];
      socket.sent.clear();
      socket.receive(_pingRequest(4242));
      await _settle();

      final message = ProtoReader.parse(socket.sent.single);
      final pong = message.readMessage(9)!; // RemotePingResponse
      expect(pong.readInt(1), 4242);
    });

    test('disconnect emits disconnected and blocks further keys', () async {
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

      await expectLater(
        channel.sendKeyCommand('HOME'),
        throwsA(isA<CommandFailure>()),
      );
    });
  });

  group('textInput', () {
    test('is null until a device is connected', () async {
      final connector = _FakeConnector();
      final channel = _channel(
        connector: connector,
        discoverer: _FakeMdnsDiscoverer(),
      );
      addTearDown(channel.dispose);
      expect(channel.textInput, isNull);
    });

    test('returns the channel once connected, and null again after '
        'disconnect', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      expect(channel.textInput, same(channel));

      await channel.disconnect();
      expect(channel.textInput, isNull);
    });

    test(
      'sendText emits one RemoteImeBatchEdit frame with a commit_text op',
      () async {
        final connector = _FakeConnector();
        final channel = await _connectedChannel(connector);
        addTearDown(channel.dispose);

        final socket = connector.sockets[0];
        socket.sent.clear();
        await channel.textInput!.sendText('hi 😀');

        final message = ProtoReader.parse(socket.sent.single);
        final batchEdit = message.readMessage(11)!; // remote_ime_batch_edit
        final op = batchEdit.readMessage(2)!; // BatchEdit op
        expect(utf8.decode(op.readBytes(1)!), 'hi 😀'); // commit_text
      },
    );

    test('sendText on an empty string is a no-op (no frame)', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      final socket = connector.sockets[0];
      socket.sent.clear();
      await channel.textInput!.sendText('');

      expect(socket.sent, isEmpty);
    });

    test(
      'sendBackspace emits a delete_surrounding_text(before:1, after:0) op',
      () async {
        final connector = _FakeConnector();
        final channel = await _connectedChannel(connector);
        addTearDown(channel.dispose);

        final socket = connector.sockets[0];
        socket.sent.clear();
        await channel.textInput!.sendBackspace();

        final message = ProtoReader.parse(socket.sent.single);
        final batchEdit = message.readMessage(11)!;
        final op = batchEdit.readMessage(2)!;
        final delete = op.readMessage(2)!; // delete_surrounding_text
        expect(delete.readInt(1), 1); // before_length
        expect(delete.readInt(2), 0); // after_length
      },
    );

    test('submit falls back to a KEYCODE_ENTER key inject', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);

      final socket = connector.sockets[0];
      socket.sent.clear();
      await channel.textInput!.submit();

      final message = ProtoReader.parse(socket.sent.single);
      final inject = message.readMessage(10)!; // remote_key_inject
      expect(inject.readInt(1), 23); // KEYCODE_DPAD_CENTER for 'ENTER' alias
      expect(inject.readInt(2), 3); // RemoteDirection.SHORT
    });

    test(
      'clear emits a delete_surrounding_text spanning the whole field, '
      'ignoring knownLength',
      () async {
        final connector = _FakeConnector();
        final channel = await _connectedChannel(connector);
        addTearDown(channel.dispose);

        final socket = connector.sockets[0];
        socket.sent.clear();
        await channel.textInput!.clear(knownLength: 3);

        // One frame, regardless of knownLength.
        expect(socket.sent, hasLength(1));
        final message = ProtoReader.parse(socket.sent.single);
        final batchEdit = message.readMessage(11)!;
        final op = batchEdit.readMessage(2)!;
        final delete = op.readMessage(2)!;
        // Both spans are far larger than any real field — the IME caps them
        // at the actual length.
        expect(delete.readInt(1), greaterThan(1000));
        expect(delete.readInt(2), greaterThan(1000));
      },
    );

    test('sendText throws CommandFailure when not connected', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      // Capture the capability handle while connected, then disconnect.
      final textInput = channel.textInput!;
      await channel.disconnect();

      await expectLater(
        textInput.sendText('x'),
        throwsA(isA<CommandFailure>()),
      );
    });

    test('clear throws CommandFailure when not connected', () async {
      final connector = _FakeConnector();
      final channel = await _connectedChannel(connector);
      addTearDown(channel.dispose);
      final textInput = channel.textInput!;
      await channel.disconnect();

      await expectLater(
        textInput.clear(),
        throwsA(isA<CommandFailure>()),
      );
    });
  });
}

/// Hands out [_FakeProtoSocket]s and records every connection attempt.
class _FakeConnector {
  final List<({String host, int port})> requests = [];
  final List<_FakeProtoSocket> sockets = [];

  /// Certificate the fake TLS peer presents — the channel reads its public key
  /// for the pairing hash.
  String serverCertificatePem = 'SERVER-CERT';

  /// Ports whose connection attempts should fail.
  final Set<int> failingPorts = {};

  Future<ProtoSocket> connect({
    required String host,
    required int port,
    required String certificatePem,
    required String privateKeyPem,
  }) async {
    requests.add((host: host, port: port));
    if (failingPorts.contains(port)) {
      throw const SocketException('connection refused');
    }
    final socket = _FakeProtoSocket(peerCertificatePem: serverCertificatePem);
    sockets.add(socket);
    return socket;
  }
}

/// In-memory [ProtoSocket] the test feeds and inspects directly.
class _FakeProtoSocket implements ProtoSocket {
  _FakeProtoSocket({this.peerCertificatePem});

  final StreamController<Uint8List> _incoming = StreamController<Uint8List>();

  /// Every (unframed) message body the channel sent, in order.
  final List<Uint8List> sent = [];
  bool closed = false;

  @override
  final String? peerCertificatePem;

  @override
  Stream<Uint8List> get messages => _incoming.stream;

  @override
  void send(List<int> message) => sent.add(Uint8List.fromList(message));

  @override
  Future<void> close() async {
    closed = true;
    if (!_incoming.isClosed) await _incoming.close();
  }

  /// Pushes an incoming protobuf message body to the listening channel.
  void receive(List<int> body) {
    if (!_incoming.isClosed) _incoming.add(Uint8List.fromList(body));
  }
}

/// [MdnsDiscoverer] whose service stream the test feeds directly.
class _FakeMdnsDiscoverer implements MdnsDiscoverer {
  final StreamController<MdnsService> _controller =
      StreamController<MdnsService>.broadcast();

  bool started = false;
  bool stopped = false;
  bool disposed = false;

  void emit(MdnsService service) => _controller.add(service);

  void emitError(Object error) => _controller.addError(error);

  @override
  Stream<MdnsService> get services => _controller.stream;

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

/// Deterministic [AndroidTvCrypto] — no real RSA, fixed certs and key numbers.
class _FakeCrypto implements AndroidTvCrypto {
  const _FakeCrypto();

  @override
  Future<AndroidTvIdentity> generateIdentity() async => const AndroidTvIdentity(
    certificatePem: 'CLIENT-CERT',
    privateKeyPem: 'CLIENT-KEY',
  );

  @override
  RsaPublicNumbers publicKeyOf(String certificatePem) {
    final modulus = certificatePem == 'SERVER-CERT'
        ? _serverModulus
        : _clientModulus;
    return RsaPublicNumbers(
      modulus: BigInt.parse(modulus, radix: 16),
      exponent: BigInt.from(65537),
    );
  }
}

/// In-memory stand-in for the credential callbacks backed by PreferencesDao.
class _CredentialStore {
  final Map<String, String> _store = {};

  Future<String?> load(String deviceId) async => _store[deviceId];

  Future<void> save(String deviceId, String credential) async =>
      _store[deviceId] = credential;
}
