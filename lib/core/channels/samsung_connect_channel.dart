import 'dart:async';
import 'dart:convert';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/channels/pointer_control.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/core/channels/ssdp_discovery.dart';
import 'package:flixsy/core/channels/text_input.dart';
import 'package:flixsy/core/channels/web_socket_connection.dart';

/// Path of the Samsung remote-control channel within the connect URL.
const String _samsungChannelPath = '/api/v2/channels/samsung.remote.control';

/// [RemoteChannel] for Samsung Tizen TVs (2016 and newer) over the
/// `ms.remote.control` WebSocket protocol.
///
/// Discovery is SSDP (`ST: urn:samsung.com:device:RemoteControlReceiver:1`).
/// A connect prefers the secure 2018+ endpoint `wss://<ip>:8002` and falls
/// back to `ws://<ip>:8001` (2016–2017, no auth). On a first pairing the TV
/// shows an Allow/Deny prompt and issues a token, which is persisted via the
/// `loadCredential` / `saveCredential` callbacks so later connections skip
/// the prompt.
///
/// The pre-2016 legacy raw-TCP protocol (port 55000) is intentionally not
/// supported.
class SamsungConnectChannel implements RemoteChannel, RemoteTextInput {
  SamsungConnectChannel({
    WebSocketConnector connector = tlsTolerantWebSocketConnector,
    SsdpDiscoverer? discovery,
    required Future<String?> Function(String deviceId) loadCredential,
    required Future<void> Function(String deviceId, String credential)
    saveCredential,
    Duration pairingTimeout = const Duration(seconds: 60),
  }) : _connector = connector,
       _ssdp = discovery ?? SsdpDiscovery(searchTarget: samsungSearchTarget),
       _loadCredential = loadCredential,
       _saveCredential = saveCredential,
       _pairingTimeout = pairingTimeout {
    _ssdpSub = _ssdp.responses.listen(
      _onSsdpResponse,
      onError: (Object error, StackTrace _) {
        final message = error is ConnectFailure
            ? error.message
            : error.toString();
        _emit({'type': 'discoveryError', 'message': message});
      },
    );
  }

  /// SSDP `ST` value Samsung TVs answer to.
  static const String samsungSearchTarget =
      'urn:samsung.com:device:RemoteControlReceiver:1';

  /// Name shown on the TV's device list, sent base64-encoded in the connect
  /// URL.
  static const String _appName = 'Flixsy';

  /// Generic key names mapped to Samsung `KEY_*` codes. Lookup is
  /// case-insensitive — keys are upper-cased before matching.
  static const Map<String, String> _keyCodes = {
    'UP': 'KEY_UP',
    'DOWN': 'KEY_DOWN',
    'LEFT': 'KEY_LEFT',
    'RIGHT': 'KEY_RIGHT',
    'OK': 'KEY_ENTER',
    'SELECT': 'KEY_ENTER',
    'ENTER': 'KEY_ENTER',
    'BACK': 'KEY_RETURN',
    'EXIT': 'KEY_EXIT',
    'HOME': 'KEY_HOME',
    'MENU': 'KEY_MENU',
    'INFO': 'KEY_INFO',
    'VOLUME_UP': 'KEY_VOLUP',
    'VOLUME_DOWN': 'KEY_VOLDOWN',
    'MUTE': 'KEY_MUTE',
    'CHANNEL_UP': 'KEY_CHUP',
    'CHANNEL_DOWN': 'KEY_CHDOWN',
    'PLAY': 'KEY_PLAY',
    'PAUSE': 'KEY_PAUSE',
    'STOP': 'KEY_STOP',
    'FAST_FORWARD': 'KEY_FF',
    'REWIND': 'KEY_REWIND',
    'POWER': 'KEY_POWER',
  };

  final WebSocketConnector _connector;
  final SsdpDiscoverer _ssdp;
  final Future<String?> Function(String deviceId) _loadCredential;
  final Future<void> Function(String deviceId, String credential)
  _saveCredential;
  final Duration _pairingTimeout;

  late final StreamSubscription<SsdpResponse> _ssdpSub;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Devices discovered this session, keyed by their `id` (the SSDP `USN`).
  final Map<String, _SamsungDevice> _devices = {};

  WebSocketConnection? _socket;
  StreamSubscription<String>? _socketSub;
  String? _connectedDeviceId;

  /// Completes when the TV sends `ms.channel.connect` (carrying the auth
  /// token, if any) or rejects the connection.
  Completer<String?>? _channelReady;

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _events.stream;

  @override
  Future<void> startDiscovery() => _ssdp.start();

  @override
  Future<void> stopDiscovery() => _ssdp.stop();

  @override
  Future<void> connectToDevice(String deviceId) async {
    final device = _devices[deviceId];
    if (device == null) {
      throw ConnectionFailure('Unknown Samsung device: $deviceId');
    }
    _teardownConnection();

    final token = await _loadCredential(deviceId);

    // Prefer the secure 2018+ endpoint; fall back to the 2016–2017 one.
    WebSocketConnection? socket;
    Object? lastError;
    for (final url in _candidateUrls(device.host, token)) {
      try {
        socket = await _connector(url);
        break;
      } on Object catch (error) {
        lastError = error;
      }
    }
    if (socket == null) {
      throw ConnectionFailure('Samsung connection failed: $lastError');
    }
    _socket = socket;
    _socketSub = socket.messages.listen(
      _handleMessage,
      onError: (Object _) {},
      onDone: _onSocketClosed,
    );

    // With no stored token the TV shows an Allow/Deny prompt — cue the user.
    if (token == null || token.isEmpty) {
      _emit({
        'type': 'pairingRequired',
        'deviceId': deviceId,
        'kind': 'confirmOnTv',
      });
    }

    final String? newToken;
    try {
      newToken = await _awaitChannelReady();
    } on ConnectFailure {
      _teardownConnection();
      rethrow;
    } on Object catch (error) {
      _teardownConnection();
      throw ConnectionFailure('Samsung handshake failed: $error');
    }
    if (newToken != null && newToken.isNotEmpty && newToken != token) {
      await _saveCredential(deviceId, newToken);
    }

    _connectedDeviceId = deviceId;
    _emit({'type': 'connectionStateChanged', 'state': 'connected'});
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDeviceId == null && _socket == null) return;
    final wasConnected = _connectedDeviceId != null;
    _teardownConnection();
    if (wasConnected) {
      _emit({'type': 'connectionStateChanged', 'state': 'disconnected'});
    }
  }

  @override
  Future<void> sendKeyCommand(String key) async {
    final keyCode = _keyCodes[key.toUpperCase()];
    if (keyCode == null) {
      throw CommandFailure('Unsupported Samsung key: $key');
    }
    _sendKey(keyCode);
  }

  /// Pushes a `SendRemoteKey` frame at the connected socket — the shared
  /// path for both [sendKeyCommand] and the [RemoteTextInput] backspace /
  /// clear key bursts.
  void _sendKey(String keyCode) {
    final socket = _requireSocket();
    socket.send(
      jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': 'Click',
          'DataOfCmd': keyCode,
          'Option': 'false',
          'TypeOfRemote': 'SendRemoteKey',
        },
      }),
    );
  }

  /// Returns the open socket, or throws [CommandFailure] if no device is
  /// currently connected.
  WebSocketConnection _requireSocket() {
    if (_connectedDeviceId == null) {
      throw const CommandFailure('Not connected to a Samsung device');
    }
    final socket = _socket;
    if (socket == null) {
      throw const CommandFailure('Samsung connection is not open');
    }
    return socket;
  }

  @override
  Future<void> submitPairingCode(String code) async {
    throw const ConnectionFailure(
      'Samsung pairing is confirmed on the TV, not by code',
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async =>
      _devices.values.map((device) => device.toMap()).toList(growable: false);

  @override
  PointerControl? get pointerControl => null;

  // --- RemoteTextInput ----------------------------------------------------
  //
  // Samsung's `ms.remote.control` channel takes a `SendInputString` frame
  // that carries the text as base64-utf8 in `DataOfCmd` (one frame for the
  // whole string — no per-character loop needed). Backspace and submit are
  // ordinary `SendRemoteKey` frames with `KEY_BACK_MZ` and `KEY_ENTER`.
  //
  // Unlike webOS, Samsung **does not ack** these frames. A frame sent when
  // no TV field is focused is silently dropped — we have no way to surface
  // that as a [CommandFailure] from the channel layer. The keyboard sheet's
  // UX simply assumes the user has a field up on the TV.
  //
  // Clear: deferred to a real-device smoke test. The plan considered an
  // empty `SendInputString` (would be a true one-shot wipe if Tizen honours
  // it), but without hardware confirmation we use the conservative fallback
  // — a [knownLength] burst of `KEY_BACK_MZ` — so `clear` always actually
  // deletes something. Revisit once the smoke test runs.

  @override
  RemoteTextInput? get textInput => _connectedDeviceId == null ? null : this;

  @override
  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    final socket = _requireSocket();
    final encoded = base64.encode(utf8.encode(text));
    socket.send(
      jsonEncode({
        'method': 'ms.remote.control',
        'params': {
          'Cmd': encoded,
          'DataOfCmd': 'base64',
          'TypeOfRemote': 'SendInputString',
        },
      }),
    );
  }

  @override
  Future<void> sendBackspace() async {
    _sendKey('KEY_BACK_MZ');
  }

  @override
  Future<void> submit() async {
    _sendKey('KEY_ENTER');
  }

  @override
  Future<void> clear({int knownLength = 0}) async {
    // Validate connection even on a 0-length clear, so the failure
    // semantics match the other methods.
    _requireSocket();
    for (var i = 0; i < knownLength; i++) {
      _sendKey('KEY_BACK_MZ');
    }
  }

  @override
  void dispose() {
    _ssdpSub.cancel();
    _ssdp.dispose();
    _teardownConnection();
    _events.close();
  }

  // --- Discovery ----------------------------------------------------------

  void _onSsdpResponse(SsdpResponse response) {
    final host = response.host;
    if (host == null || host.isEmpty) return;
    final device = _SamsungDevice(id: response.usn, host: host);
    _devices[device.id] = device;
    _emit({'type': 'deviceFound', 'device': device.toMap()});
  }

  // --- Connection ---------------------------------------------------------

  /// The connect URLs to try, in order: the secure 2018+ endpoint first, then
  /// the older plaintext one. [token], when present, skips the pairing
  /// prompt.
  List<String> _candidateUrls(String host, String? token) {
    final name = base64.encode(utf8.encode(_appName));
    final tokenParam = token != null && token.isNotEmpty ? '&token=$token' : '';
    return [
      'wss://$host:8002$_samsungChannelPath?name=$name$tokenParam',
      'ws://$host:8001$_samsungChannelPath?name=$name',
    ];
  }

  /// Waits for the TV's `ms.channel.connect`, returning the auth token it
  /// carries (or `null`). Throws [ConnectionFailure] if the TV denies the
  /// connection or never answers.
  Future<String?> _awaitChannelReady() async {
    final completer = Completer<String?>();
    _channelReady = completer;
    try {
      return await completer.future.timeout(_pairingTimeout);
    } on TimeoutException {
      _channelReady = null;
      throw const ConnectionFailure('Samsung pairing timed out');
    }
  }

  void _handleMessage(String raw) {
    final Map<String, dynamic> message;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return;
      message = decoded;
    } on FormatException {
      return;
    }
    final completer = _channelReady;
    if (completer == null || completer.isCompleted) return;
    switch (message['event']) {
      case 'ms.channel.connect':
        final data = message['data'];
        final token = data is Map ? data['token'] : null;
        _channelReady = null;
        completer.complete(token is String ? token : null);
      case 'ms.channel.unauthorized':
        _channelReady = null;
        completer.completeError(
          const ConnectionFailure('Samsung pairing was denied'),
        );
      case 'ms.channel.timeOut':
        _channelReady = null;
        completer.completeError(
          const ConnectionFailure('Samsung pairing timed out'),
        );
    }
  }

  void _onSocketClosed() {
    final wasConnected = _connectedDeviceId != null;
    _teardownConnection();
    if (wasConnected) {
      _emit({'type': 'connectionStateChanged', 'state': 'disconnected'});
    }
  }

  void _teardownConnection() {
    _socketSub?.cancel();
    _socketSub = null;
    _socket?.close();
    _socket = null;
    final pending = _channelReady;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(
        const ConnectionFailure('Samsung connection closed'),
      );
    }
    _channelReady = null;
    _connectedDeviceId = null;
  }

  void _emit(Map<String, dynamic> event) {
    if (!_events.isClosed) _events.add(event);
  }
}

/// A discovered Samsung TV and the host its remote-control socket lives on.
class _SamsungDevice {
  const _SamsungDevice({required this.id, required this.host});

  final String id;
  final String host;

  /// The `device` payload shape consumed by `DeviceDiscoveryNotifier`.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': 'Samsung TV',
    'ipAddress': host,
    'modelName': '',
  };
}
