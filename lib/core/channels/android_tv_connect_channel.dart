import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/channels/android_tv_crypto.dart';
import 'package:flixsy/core/channels/mdns_discovery.dart';
import 'package:flixsy/core/channels/pointer_control.dart';
import 'package:flixsy/core/channels/proto_codec.dart';
import 'package:flixsy/core/channels/proto_socket.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/core/channels/text_input.dart';

// --- Protocol constants -----------------------------------------------------
//
// Field numbers below are taken verbatim from the Android TV Remote v2
// `.proto` definitions (`polo.proto` for pairing, `remotemessage.proto` for
// the remote control). Both envelopes are dispatched by "which sub-message
// field is set" rather than a protobuf `oneof`.

/// `OuterMessage.protocol_version` — the pairing protocol revision. The
/// reference client sends `2`.
const int _fProtocolVersion = 1;

/// `OuterMessage.status`.
const int _fStatus = 2;

/// `OuterMessage.pairing_request`.
const int _fPairingRequest = 10;

/// `OuterMessage.pairing_request_ack`.
const int _fPairingRequestAck = 11;

/// `OuterMessage.options`.
const int _fOptions = 20;

/// `OuterMessage.configuration`.
const int _fConfiguration = 30;

/// `OuterMessage.configuration_ack`.
const int _fConfigurationAck = 31;

/// `OuterMessage.secret`.
const int _fSecret = 40;

/// `OuterMessage.secret_ack`.
const int _fSecretAck = 41;

/// `OuterMessage.Status.STATUS_OK` — any other status means the TV rejected a
/// pairing message.
const int _statusOk = 200;

/// `RemoteMessage.remote_configure`.
const int _fRemoteConfigure = 1;

/// `RemoteMessage.remote_set_active`.
const int _fRemoteSetActive = 2;

/// `RemoteMessage.remote_ping_request`.
const int _fRemotePingRequest = 8;

/// `RemoteMessage.remote_ping_response`.
const int _fRemotePingResponse = 9;

/// `RemoteMessage.remote_key_inject`.
const int _fRemoteKeyInject = 10;

/// `RemoteMessage.remote_ime_batch_edit` — the text-injection envelope. Carries
/// an editInfo plus a list of commit/delete operations applied to the focused
/// TV field in one frame.
const int _fRemoteImeBatchEdit = 11;

/// `RemoteMessage.remote_start`.
const int _fRemoteStart = 40;

/// `RemoteImeBatchEdit.BatchEdit.commit_text` — inserts a string at the cursor.
const int _fBatchEditCommitText = 1;

/// `RemoteImeBatchEdit.BatchEdit.delete_surrounding_text` — deletes characters
/// around the cursor. The nested message carries `before_length` and
/// `after_length` field 1 / 2.
const int _fBatchEditDeleteSurrounding = 2;

/// `DeleteSurroundingText.before_length` — characters to delete to the left
/// of the cursor.
const int _fDeleteBeforeLength = 1;

/// `DeleteSurroundingText.after_length` — characters to delete to the right
/// of the cursor.
const int _fDeleteAfterLength = 2;

/// `RemoteImeBatchEdit.batch_edit` — repeated field carrying the ordered list
/// of commit/delete operations applied to the focused field.
const int _fBatchEditOps = 2;

/// A "clear the whole field" delete amount the Android IME framework caps at
/// the actual field length — one frame, no caller-supplied length needed.
const int _clearDeleteSpan = 9999;

/// `RemoteDirection.SHORT` — a normal key tap (as opposed to a long-press).
const int _directionShort = 3;

/// `Options.Encoding.EncodingType.ENCODING_TYPE_HEXADECIMAL`.
const int _encodingHexadecimal = 3;

/// `Options.RoleType.ROLE_TYPE_INPUT` — the role a remote-control client takes.
const int _roleInput = 1;

/// Length of the hexadecimal pairing code the TV displays.
const int _pairingCodeLength = 6;

// `Feature` bit flags, used for both `RemoteConfigure.code1` and
// `RemoteSetActive.active`. The client requests this set and then masks it
// down to whatever the TV reports as supported.
const int _featurePing = 1 << 0;
const int _featureKey = 1 << 1;
const int _featurePower = 1 << 5;
const int _featureVolume = 1 << 6;
const int _featureAppLink = 1 << 9;
const int _requestedFeatures =
    _featurePing |
    _featureKey |
    _featurePower |
    _featureVolume |
    _featureAppLink;

/// [RemoteChannel] for Google / Android TV devices over the Android TV Remote
/// v2 protocol.
///
/// Discovery is mDNS (`_androidtvremote2._tcp`). Control is protobuf framed
/// over TLS: a one-time pairing exchange on port 6467 (the TV shows a 6-digit
/// hex code, fed back via [submitPairingCode]) establishes trust in a
/// self-signed client certificate, after which the same certificate
/// authenticates the remote-control connection on port 6466.
///
/// The generated client certificate is the pairing credential — it persists
/// through the `loadCredential` / `saveCredential` callbacks, so a paired TV
/// reconnects without showing the code again. The TLS transport, the mDNS
/// discoverer, and the crypto are all injectable for testing.
class AndroidTvConnectChannel implements RemoteChannel, RemoteTextInput {
  AndroidTvConnectChannel({
    ProtoSocketConnector connector = secureProtoSocketConnector,
    MdnsDiscoverer? discovery,
    AndroidTvCrypto crypto = const BasicUtilsAndroidTvCrypto(),
    required Future<String?> Function(String deviceId) loadCredential,
    required Future<void> Function(String deviceId, String credential)
    saveCredential,
    Duration pairingTimeout = const Duration(minutes: 2),
    Duration handshakeTimeout = const Duration(seconds: 15),
    Duration idleTimeout = const Duration(seconds: 16),
  }) : _connector = connector,
       _mdns = discovery ?? MdnsDiscovery(serviceType: androidTvServiceType),
       _crypto = crypto,
       _loadCredential = loadCredential,
       _saveCredential = saveCredential,
       _pairingTimeout = pairingTimeout,
       _handshakeTimeout = handshakeTimeout,
       _idleTimeout = idleTimeout {
    _mdnsSub = _mdns.services.listen(
      _onServiceFound,
      onError: (Object error, StackTrace _) {
        final message = error is ConnectFailure
            ? error.message
            : error.toString();
        _emit({'type': 'discoveryError', 'message': message});
      },
    );
  }

  /// The DNS-SD service type Android TV devices advertise.
  static const String androidTvServiceType = '_androidtvremote2._tcp';

  /// The pairing port is conventionally one above the discovered remote port.
  static const int _pairingPortOffset = 1;

  /// Generic key names mapped to Android `KEYCODE_*` values. Lookup is
  /// case-insensitive — keys are upper-cased before matching.
  static const Map<String, int> _keyCodes = {
    'UP': 19, // KEYCODE_DPAD_UP
    'DOWN': 20, // KEYCODE_DPAD_DOWN
    'LEFT': 21, // KEYCODE_DPAD_LEFT
    'RIGHT': 22, // KEYCODE_DPAD_RIGHT
    'OK': 23, // KEYCODE_DPAD_CENTER
    'SELECT': 23,
    'ENTER': 23,
    'BACK': 4, // KEYCODE_BACK
    'HOME': 3, // KEYCODE_HOME
    'MENU': 82, // KEYCODE_MENU
    'INFO': 165, // KEYCODE_INFO
    'VOLUME_UP': 24, // KEYCODE_VOLUME_UP
    'VOLUME_DOWN': 25, // KEYCODE_VOLUME_DOWN
    'MUTE': 164, // KEYCODE_VOLUME_MUTE
    'CHANNEL_UP': 166, // KEYCODE_CHANNEL_UP
    'CHANNEL_DOWN': 167, // KEYCODE_CHANNEL_DOWN
    'PLAY': 126, // KEYCODE_MEDIA_PLAY
    'PAUSE': 127, // KEYCODE_MEDIA_PAUSE
    'PLAY_PAUSE': 85, // KEYCODE_MEDIA_PLAY_PAUSE
    'STOP': 86, // KEYCODE_MEDIA_STOP
    'FAST_FORWARD': 90, // KEYCODE_MEDIA_FAST_FORWARD
    'REWIND': 89, // KEYCODE_MEDIA_REWIND
    'NEXT': 87, // KEYCODE_MEDIA_NEXT
    'PREVIOUS': 88, // KEYCODE_MEDIA_PREVIOUS
    'POWER': 26, // KEYCODE_POWER
  };

  final ProtoSocketConnector _connector;
  final MdnsDiscoverer _mdns;
  final AndroidTvCrypto _crypto;
  final Future<String?> Function(String deviceId) _loadCredential;
  final Future<void> Function(String deviceId, String credential)
  _saveCredential;
  final Duration _pairingTimeout;
  final Duration _handshakeTimeout;
  final Duration _idleTimeout;

  late final StreamSubscription<MdnsService> _mdnsSub;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Devices discovered this session, keyed by their `id` (the mDNS name).
  final Map<String, _AndroidTvDevice> _devices = {};

  // Pairing connection (port 6467) state.
  ProtoSocket? _pairingSocket;
  StreamSubscription<Uint8List>? _pairingSub;
  Completer<void>? _pairingDone;
  AndroidTvIdentity? _pairingIdentity;
  String? _serverCertificatePem;
  String? _pairingDeviceId;
  bool _awaitingCode = false;

  // Remote-control connection (port 6466) state.
  ProtoSocket? _remoteSocket;
  StreamSubscription<Uint8List>? _remoteSub;
  Completer<void>? _remoteReady;
  String? _connectedDeviceId;
  int _activeFeatures = _requestedFeatures;
  Timer? _idleTimer;

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _events.stream;

  @override
  Future<void> startDiscovery() => _mdns.start();

  @override
  Future<void> stopDiscovery() => _mdns.stop();

  @override
  Future<void> connectToDevice(String deviceId) async {
    final device = _devices[deviceId];
    if (device == null) {
      throw ConnectionFailure('Unknown Android TV device: $deviceId');
    }
    _teardownConnection();
    _pairingDeviceId = deviceId;
    try {
      final stored = await _loadCredential(deviceId);
      var identity = _tryDecodeIdentity(stored);
      if (identity == null) {
        // No (or unusable) credential — generate a certificate and pair.
        identity = await _crypto.generateIdentity();
        await _pair(device, identity);
        await _saveCredential(deviceId, _encodeIdentity(identity));
      }
      await _connectRemote(device, identity);
      _connectedDeviceId = deviceId;
      _emit({'type': 'connectionStateChanged', 'state': 'connected'});
    } on ConnectFailure {
      _teardownConnection();
      rethrow;
    } on Object catch (error) {
      _teardownConnection();
      throw ConnectionFailure('Android TV connection failed: $error');
    } finally {
      _pairingDeviceId = null;
    }
  }

  @override
  Future<void> submitPairingCode(String code) async {
    if (!_awaitingCode || _pairingSocket == null || _pairingDone == null) {
      throw const ConnectionFailure('No Android TV pairing is awaiting a code');
    }
    final identity = _pairingIdentity;
    final serverPem = _serverCertificatePem;
    if (identity == null || serverPem == null) {
      throw const ConnectionFailure('Android TV pairing state is incomplete');
    }
    final trimmed = code.trim();
    final Uint8List digest;
    try {
      digest = computePairingSecret(
        clientKey: _crypto.publicKeyOf(identity.certificatePem),
        serverKey: _crypto.publicKeyOf(serverPem),
        pairingCode: trimmed,
      );
    } on ConnectFailure {
      rethrow;
    } on Object catch (error) {
      throw ConnectionFailure('Could not compute the pairing secret: $error');
    }
    // The first hex byte of the code is a check digit over the digest; a
    // mismatch means the user mistyped it — let them try again.
    final checkByte = int.parse(trimmed.substring(0, 2), radix: 16);
    if (digest.isEmpty || digest[0] != checkByte) {
      throw const ConnectionFailure(
        'Incorrect pairing code — check the code shown on your TV',
      );
    }
    _awaitingCode = false;
    _pairingSocket?.send(_secretMessage(digest));
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDeviceId == null && _remoteSocket == null) return;
    final wasConnected = _connectedDeviceId != null;
    _teardownConnection();
    if (wasConnected) {
      _emit({'type': 'connectionStateChanged', 'state': 'disconnected'});
    }
  }

  @override
  Future<void> sendKeyCommand(String key) async {
    if (_connectedDeviceId == null) {
      throw const CommandFailure('Not connected to an Android TV');
    }
    final socket = _remoteSocket;
    if (socket == null) {
      throw const CommandFailure('Android TV connection is not open');
    }
    final keyCode = _keyCodes[key.toUpperCase()];
    if (keyCode == null) {
      throw CommandFailure('Unsupported Android TV key: $key');
    }
    socket.send(_keyInjectMessage(keyCode));
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async =>
      _devices.values.map((device) => device.toMap()).toList(growable: false);

  @override
  PointerControl? get pointerControl => null;

  @override
  RemoteTextInput? get textInput => _connectedDeviceId == null ? null : this;

  // --- RemoteTextInput ----------------------------------------------------
  //
  // Android TV exposes a dedicated text path on the remote-control socket:
  // `RemoteImeBatchEdit` frames carry commit/delete operations the IME applies
  // to whatever field currently has focus. Submit falls back to `KEYCODE_ENTER`
  // through the existing key-inject path — works for any focused field, and
  // sidesteps the under-documented `RemoteImeShowAction` editor-action codes.

  @override
  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    final socket = _requireRemoteSocket();
    socket.send(_imeBatchEditMessage(_commitTextOp(text)));
  }

  @override
  Future<void> sendBackspace() async {
    final socket = _requireRemoteSocket();
    socket.send(_imeBatchEditMessage(_deleteSurroundingOp(before: 1, after: 0)));
  }

  @override
  Future<void> submit() async {
    final socket = _requireRemoteSocket();
    final keyCode = _keyCodes['ENTER']!;
    socket.send(_keyInjectMessage(keyCode));
  }

  @override
  Future<void> clear({int knownLength = 0}) async {
    final socket = _requireRemoteSocket();
    // The IME framework caps delete-surrounding at the actual field length,
    // so a single span far larger than any real field clears it in one frame.
    // [knownLength] is intentionally ignored — Android TV doesn't need it.
    socket.send(
      _imeBatchEditMessage(
        _deleteSurroundingOp(before: _clearDeleteSpan, after: _clearDeleteSpan),
      ),
    );
  }

  ProtoSocket _requireRemoteSocket() {
    if (_connectedDeviceId == null) {
      throw const CommandFailure('Not connected to an Android TV');
    }
    final socket = _remoteSocket;
    if (socket == null) {
      throw const CommandFailure('Android TV connection is not open');
    }
    return socket;
  }

  @override
  void dispose() {
    _mdnsSub.cancel();
    _mdns.dispose();
    _teardownConnection();
    _events.close();
  }

  // --- Discovery ----------------------------------------------------------

  void _onServiceFound(MdnsService service) {
    final device = _AndroidTvDevice(
      id: service.name,
      name: _friendlyName(service.name),
      host: service.address,
      remotePort: service.port,
    );
    _devices[device.id] = device;
    _emit({'type': 'deviceFound', 'device': device.toMap()});
  }

  /// Derives a human-readable name from a DNS-SD instance name such as
  /// `Living Room TV._androidtvremote2._tcp.local`.
  String _friendlyName(String instanceName) {
    final cut = instanceName.indexOf('._');
    final label = cut > 0 ? instanceName.substring(0, cut) : instanceName;
    return label.isEmpty ? 'Android TV' : label;
  }

  // --- Pairing (port 6467) ------------------------------------------------

  Future<void> _pair(
    _AndroidTvDevice device,
    AndroidTvIdentity identity,
  ) async {
    _pairingIdentity = identity;
    final ProtoSocket socket;
    try {
      socket = await _connector(
        host: device.host,
        port: device.pairingPort,
        certificatePem: identity.certificatePem,
        privateKeyPem: identity.privateKeyPem,
      );
    } on ConnectFailure {
      rethrow;
    } on Object catch (error) {
      throw ConnectionFailure('Android TV pairing connection failed: $error');
    }
    _pairingSocket = socket;
    _serverCertificatePem = socket.peerCertificatePem;

    final done = Completer<void>();
    _pairingDone = done;
    _pairingSub = socket.messages.listen(
      _handlePairingMessage,
      onError: (Object _) {},
      onDone: () {
        if (!done.isCompleted) {
          done.completeError(
            const ConnectionFailure('Android TV closed the pairing connection'),
          );
        }
      },
    );

    socket.send(_pairingRequestMessage());
    try {
      await done.future.timeout(_pairingTimeout);
    } on TimeoutException {
      throw const ConnectionFailure('Android TV pairing timed out');
    } finally {
      await _pairingSub?.cancel();
      _pairingSub = null;
      await _pairingSocket?.close();
      _pairingSocket = null;
      _pairingDone = null;
      _awaitingCode = false;
    }
  }

  void _handlePairingMessage(Uint8List body) {
    final done = _pairingDone;
    if (done == null || done.isCompleted) return;
    final ProtoReader message;
    try {
      message = ProtoReader.parse(body);
    } on FormatException {
      return;
    }
    final status = message.readInt(_fStatus);
    if (status != null && status != _statusOk) {
      done.completeError(
        ConnectionFailure('Android TV rejected pairing (status $status)'),
      );
      return;
    }
    if (message.has(_fPairingRequestAck)) {
      _pairingSocket?.send(_optionsMessage());
    } else if (message.has(_fOptions)) {
      _pairingSocket?.send(_configurationMessage());
    } else if (message.has(_fConfigurationAck)) {
      // The TV is now showing its code; cue the user to enter it.
      _awaitingCode = true;
      final deviceId = _pairingDeviceId;
      if (deviceId != null) {
        _emit({
          'type': 'pairingRequired',
          'deviceId': deviceId,
          'kind': 'enterCode',
        });
      }
    } else if (message.has(_fSecretAck)) {
      done.complete();
    }
  }

  // --- Remote control (port 6466) -----------------------------------------

  Future<void> _connectRemote(
    _AndroidTvDevice device,
    AndroidTvIdentity identity,
  ) async {
    final ProtoSocket socket;
    try {
      socket = await _connector(
        host: device.host,
        port: device.remotePort,
        certificatePem: identity.certificatePem,
        privateKeyPem: identity.privateKeyPem,
      );
    } on ConnectFailure {
      rethrow;
    } on Object catch (error) {
      throw ConnectionFailure('Android TV connection failed: $error');
    }
    _remoteSocket = socket;
    _activeFeatures = _requestedFeatures;

    final ready = Completer<void>();
    _remoteReady = ready;
    _remoteSub = socket.messages.listen(
      _handleRemoteMessage,
      onError: (Object _) {},
      onDone: _onRemoteClosed,
    );

    try {
      await ready.future.timeout(_handshakeTimeout);
    } on TimeoutException {
      throw const ConnectionFailure('Android TV remote handshake timed out');
    } finally {
      _remoteReady = null;
    }
    _armIdleTimer();
  }

  void _handleRemoteMessage(Uint8List body) {
    _resetIdleTimer();
    final ProtoReader message;
    try {
      message = ProtoReader.parse(body);
    } on FormatException {
      return;
    }
    if (message.has(_fRemoteConfigure)) {
      final configure = message.readMessage(_fRemoteConfigure);
      final supported = configure?.readInt(1) ?? _requestedFeatures;
      _activeFeatures = _requestedFeatures & supported;
      _remoteSocket?.send(_remoteConfigureMessage());
    } else if (message.has(_fRemoteSetActive)) {
      _remoteSocket?.send(_remoteSetActiveMessage());
    } else if (message.has(_fRemoteStart)) {
      final ready = _remoteReady;
      if (ready != null && !ready.isCompleted) ready.complete();
    } else if (message.has(_fRemotePingRequest)) {
      final ping = message.readMessage(_fRemotePingRequest);
      _remoteSocket?.send(_pingResponseMessage(ping?.readInt(1) ?? 0));
    }
  }

  void _onRemoteClosed() {
    final wasConnected = _connectedDeviceId != null;
    _teardownConnection();
    if (wasConnected) {
      _emit({'type': 'connectionStateChanged', 'state': 'disconnected'});
    }
  }

  /// Arms the idle-disconnect timer once the remote handshake is complete.
  void _armIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleTimeout, _onIdleTimeout);
  }

  /// Restarts the idle timer on any traffic — but only once [_armIdleTimer]
  /// has armed it, so handshake messages do not start the clock early.
  void _resetIdleTimer() {
    if (_idleTimer == null) return;
    _idleTimer!.cancel();
    _idleTimer = Timer(_idleTimeout, _onIdleTimeout);
  }

  void _onIdleTimeout() {
    final wasConnected = _connectedDeviceId != null;
    _teardownConnection();
    if (wasConnected) {
      _emit({'type': 'connectionStateChanged', 'state': 'disconnected'});
    }
  }

  // --- Message builders ---------------------------------------------------

  /// Wraps [sub] in an `OuterMessage` envelope at field [subField].
  Uint8List _outerMessage(int subField, ProtoWriter sub) =>
      (ProtoWriter()
            ..writeVarint(_fProtocolVersion, 2)
            ..writeVarint(_fStatus, _statusOk)
            ..writeMessage(subField, sub))
          .toBytes();

  Uint8List _pairingRequestMessage() => _outerMessage(
    _fPairingRequest,
    ProtoWriter()
      ..writeString(1, 'atvremote') // service_name
      ..writeString(2, 'Flixsy'), // client_name
  );

  /// The hexadecimal, 6-symbol encoding both [_optionsMessage] and
  /// [_configurationMessage] negotiate.
  ProtoWriter _hexEncoding() => ProtoWriter()
    ..writeVarint(1, _encodingHexadecimal) // type
    ..writeVarint(2, _pairingCodeLength); // symbol_length

  Uint8List _optionsMessage() => _outerMessage(
    _fOptions,
    ProtoWriter()
      ..writeMessage(1, _hexEncoding()) // input_encodings
      ..writeVarint(3, _roleInput), // preferred_role
  );

  Uint8List _configurationMessage() => _outerMessage(
    _fConfiguration,
    ProtoWriter()
      ..writeMessage(1, _hexEncoding()) // encoding
      ..writeVarint(2, _roleInput), // client_role
  );

  Uint8List _secretMessage(Uint8List digest) =>
      _outerMessage(_fSecret, ProtoWriter()..writeBytes(1, digest));

  Uint8List _remoteConfigureMessage() {
    final deviceInfo = ProtoWriter()
      ..writeVarint(3, 1) // unknown1
      ..writeString(4, '1') // unknown2
      ..writeString(5, 'atvremote') // package_name
      ..writeString(6, '1.0.0'); // app_version
    final configure = ProtoWriter()
      ..writeVarint(1, _activeFeatures) // code1
      ..writeMessage(2, deviceInfo); // device_info
    return (ProtoWriter()..writeMessage(_fRemoteConfigure, configure))
        .toBytes();
  }

  Uint8List _remoteSetActiveMessage() {
    final setActive = ProtoWriter()..writeVarint(1, _activeFeatures);
    return (ProtoWriter()..writeMessage(_fRemoteSetActive, setActive))
        .toBytes();
  }

  Uint8List _pingResponseMessage(int value) {
    final pong = ProtoWriter()..writeVarint(1, value);
    return (ProtoWriter()..writeMessage(_fRemotePingResponse, pong)).toBytes();
  }

  Uint8List _keyInjectMessage(int keyCode) {
    final inject = ProtoWriter()
      ..writeVarint(1, keyCode) // key_code
      ..writeVarint(2, _directionShort); // direction
    return (ProtoWriter()..writeMessage(_fRemoteKeyInject, inject)).toBytes();
  }

  /// One `RemoteImeBatchEdit.BatchEdit` carrying a `commit_text` operation.
  ProtoWriter _commitTextOp(String text) =>
      ProtoWriter()..writeString(_fBatchEditCommitText, text);

  /// One `RemoteImeBatchEdit.BatchEdit` carrying a `delete_surrounding_text`
  /// operation.
  ProtoWriter _deleteSurroundingOp({required int before, required int after}) {
    final delete = ProtoWriter()
      ..writeVarint(_fDeleteBeforeLength, before)
      ..writeVarint(_fDeleteAfterLength, after);
    return ProtoWriter()..writeMessage(_fBatchEditDeleteSurrounding, delete);
  }

  /// Wraps a single batch-edit operation in a `RemoteMessage` envelope. We
  /// emit one op per frame today — Android TV accepts repeated ops in one
  /// frame, but per-op framing keeps the diff/queue model in
  /// [`KeyboardSessionNotifier`] honest about which op succeeded vs failed.
  Uint8List _imeBatchEditMessage(ProtoWriter op) {
    final batchEdit = ProtoWriter()..writeMessage(_fBatchEditOps, op);
    return (ProtoWriter()..writeMessage(_fRemoteImeBatchEdit, batchEdit))
        .toBytes();
  }

  // --- Credential bundle --------------------------------------------------

  /// Decodes a stored credential into an identity, or returns `null` when the
  /// device has never paired or the stored value is unusable (forcing a fresh
  /// pairing rather than a hard failure).
  AndroidTvIdentity? _tryDecodeIdentity(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    try {
      final decoded = jsonDecode(stored);
      if (decoded is! Map) return null;
      final cert = decoded['cert'];
      final key = decoded['key'];
      if (cert is! String || key is! String || cert.isEmpty || key.isEmpty) {
        return null;
      }
      return AndroidTvIdentity(certificatePem: cert, privateKeyPem: key);
    } on FormatException {
      return null;
    }
  }

  String _encodeIdentity(AndroidTvIdentity identity) => jsonEncode({
    'cert': identity.certificatePem,
    'key': identity.privateKeyPem,
  });

  // --- Teardown -----------------------------------------------------------

  void _teardownConnection() {
    _idleTimer?.cancel();
    _idleTimer = null;
    _pairingSub?.cancel();
    _pairingSub = null;
    _pairingSocket?.close();
    _pairingSocket = null;
    _remoteSub?.cancel();
    _remoteSub = null;
    _remoteSocket?.close();
    _remoteSocket = null;

    final pairingDone = _pairingDone;
    if (pairingDone != null && !pairingDone.isCompleted) {
      pairingDone.completeError(
        const ConnectionFailure('Android TV pairing was cancelled'),
      );
    }
    _pairingDone = null;

    final remoteReady = _remoteReady;
    if (remoteReady != null && !remoteReady.isCompleted) {
      remoteReady.completeError(
        const ConnectionFailure('Android TV connection was closed'),
      );
    }
    _remoteReady = null;

    _awaitingCode = false;
    _pairingIdentity = null;
    _serverCertificatePem = null;
    _connectedDeviceId = null;
  }

  void _emit(Map<String, dynamic> event) {
    if (!_events.isClosed) _events.add(event);
  }
}

/// A discovered Android TV and the host its remote-control sockets live on.
class _AndroidTvDevice {
  const _AndroidTvDevice({
    required this.id,
    required this.name,
    required this.host,
    required this.remotePort,
  });

  final String id;
  final String name;
  final String host;

  /// The Android TV Remote v2 control port, from the mDNS SRV record (6466).
  final int remotePort;

  /// The pairing port — conventionally one above the remote port (6467).
  int get pairingPort =>
      remotePort + AndroidTvConnectChannel._pairingPortOffset;

  /// The `device` payload shape consumed by `DeviceDiscoveryNotifier`.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ipAddress': host,
    'modelName': '',
  };
}
