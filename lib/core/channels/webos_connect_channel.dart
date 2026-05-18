import 'dart:async';
import 'dart:convert';

import '../errors/connect_failure.dart';
import 'remote_channel.dart';
import 'ssdp_discovery.dart';
import 'web_socket_connection.dart';

/// Default port for the webOS SSAP WebSocket.
const int _webosPort = 3000;

/// Id used for the one-shot SSAP `register` handshake message.
const String _registerRequestId = 'register_0';

/// [RemoteChannel] for LG webOS TVs over the SSAP protocol.
///
/// Discovery is SSDP (`ST: urn:lge-com:service:webos-second-screen:1`).
/// Control runs over a WebSocket: a `register` handshake pairs with the TV
/// (the TV shows an on-screen prompt the first time and issues a persistent
/// "client-key"), after which a second "pointer input" socket carries the
/// remote-control button presses.
///
/// The WebSocket transport and the SSDP discoverer are both injectable for
/// testing; pairing keys persist through the `loadCredential` /
/// `saveCredential` callbacks.
class WebosConnectChannel implements RemoteChannel {
  WebosConnectChannel({
    WebSocketConnector connector = defaultWebSocketConnector,
    SsdpDiscoverer? discovery,
    required Future<String?> Function(String deviceId) loadCredential,
    required Future<void> Function(String deviceId, String credential)
    saveCredential,
    Duration pairingTimeout = const Duration(seconds: 60),
    Duration requestTimeout = const Duration(seconds: 8),
  }) : _connector = connector,
       _ssdp = discovery ?? SsdpDiscovery(searchTarget: webosSearchTarget),
       _loadCredential = loadCredential,
       _saveCredential = saveCredential,
       _pairingTimeout = pairingTimeout,
       _requestTimeout = requestTimeout {
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

  /// SSDP `ST` value LG webOS TVs answer to.
  static const String webosSearchTarget =
      'urn:lge-com:service:webos-second-screen:1';

  /// Generic key names mapped to webOS pointer-socket button names. Lookup is
  /// case-insensitive — keys are upper-cased before matching.
  static const Map<String, String> _buttonNames = {
    'UP': 'UP',
    'DOWN': 'DOWN',
    'LEFT': 'LEFT',
    'RIGHT': 'RIGHT',
    'OK': 'ENTER',
    'SELECT': 'ENTER',
    'ENTER': 'ENTER',
    'BACK': 'BACK',
    'EXIT': 'EXIT',
    'HOME': 'HOME',
    'MENU': 'MENU',
    'INFO': 'INFO',
    'VOLUME_UP': 'VOLUMEUP',
    'VOLUME_DOWN': 'VOLUMEDOWN',
    'MUTE': 'MUTE',
    'CHANNEL_UP': 'CHANNELUP',
    'CHANNEL_DOWN': 'CHANNELDOWN',
    'PLAY': 'PLAY',
    'PAUSE': 'PAUSE',
    'STOP': 'STOP',
    'FAST_FORWARD': 'FASTFORWARD',
    'REWIND': 'REWIND',
  };

  /// SSAP registration manifest. With `pairingType: PROMPT` the TV gates
  /// access on its on-screen prompt, so an unsigned manifest is sufficient.
  static const Map<String, dynamic> _registerManifest = {
    'manifestVersion': 1,
    'permissions': [
      'LAUNCH',
      'LAUNCH_WEBAPP',
      'APP_TO_APP',
      'CONTROL_AUDIO',
      'CONTROL_DISPLAY',
      'CONTROL_INPUT_JOYSTICK',
      'CONTROL_INPUT_MEDIA_PLAYBACK',
      'CONTROL_INPUT_TV',
      'CONTROL_POWER',
      'CONTROL_INPUT_TEXT',
      'CONTROL_MOUSE_AND_KEYBOARD',
      'READ_INSTALLED_APPS',
      'READ_INPUT_DEVICE_LIST',
      'READ_NETWORK_STATE',
      'READ_TV_CHANNEL_LIST',
      'READ_CURRENT_CHANNEL',
      'READ_RUNNING_APPS',
      'WRITE_NOTIFICATION_TOAST',
    ],
  };

  final WebSocketConnector _connector;
  final SsdpDiscoverer _ssdp;
  final Future<String?> Function(String deviceId) _loadCredential;
  final Future<void> Function(String deviceId, String credential)
  _saveCredential;
  final Duration _pairingTimeout;
  final Duration _requestTimeout;

  late final StreamSubscription<SsdpResponse> _ssdpSub;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Devices discovered this session, keyed by their `id` (the SSDP `USN`).
  final Map<String, _WebosDevice> _devices = {};

  /// In-flight SSAP requests awaiting a response, keyed by message id.
  final Map<String, Completer<Map<String, dynamic>>> _pendingRequests = {};

  WebSocketConnection? _socket;
  StreamSubscription<String>? _socketSub;
  WebSocketConnection? _pointerSocket;
  StreamSubscription<String>? _pointerSub;
  String? _connectedDeviceId;
  int _requestCounter = 0;

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
      throw ConnectionFailure('Unknown webOS device: $deviceId');
    }
    _teardownConnection();

    final WebSocketConnection socket;
    try {
      socket = await _connector('ws://${device.host}:$_webosPort');
    } on Object catch (error) {
      throw ConnectionFailure('webOS connection failed: $error');
    }
    _socket = socket;
    _socketSub = socket.messages.listen(
      _handleMessage,
      onError: (Object _) {},
      onDone: _onSocketClosed,
    );

    try {
      await _register(deviceId);
      await _openPointerSocket();
    } on ConnectFailure {
      _teardownConnection();
      rethrow;
    } on Object catch (error) {
      _teardownConnection();
      throw ConnectionFailure('webOS handshake failed: $error');
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
    if (_connectedDeviceId == null) {
      throw const CommandFailure('Not connected to a webOS device');
    }
    final pointer = _pointerSocket;
    if (pointer == null) {
      throw const CommandFailure('webOS pointer socket is not open');
    }
    final button = _buttonNames[key.toUpperCase()];
    if (button == null) {
      throw CommandFailure('Unsupported webOS key: $key');
    }
    // The pointer input socket takes plain-text `field:value` frames.
    pointer.send('type:button\nname:$button\n\n');
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async =>
      _devices.values.map((device) => device.toMap()).toList(growable: false);

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
    final device = _WebosDevice(id: response.usn, host: host);
    _devices[device.id] = device;
    _emit({'type': 'deviceFound', 'device': device.toMap()});
  }

  // --- SSAP handshake -----------------------------------------------------

  /// Sends the `register` request and waits for the TV to pair. On a first
  /// pairing the TV shows an on-screen prompt; once accepted it returns a
  /// client-key, which is persisted for next time.
  Future<void> _register(String deviceId) async {
    final storedKey = await _loadCredential(deviceId);
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[_registerRequestId] = completer;

    _send({
      'id': _registerRequestId,
      'type': 'register',
      'payload': {
        'forcePairing': false,
        'pairingType': 'PROMPT',
        'client-key': ?storedKey,
        'manifest': _registerManifest,
      },
    });

    final Map<String, dynamic> response;
    try {
      response = await completer.future.timeout(_pairingTimeout);
    } on TimeoutException {
      _pendingRequests.remove(_registerRequestId);
      throw const ConnectionFailure('webOS pairing timed out');
    }

    final payload = response['payload'];
    final clientKey = payload is Map ? payload['client-key'] : null;
    if (clientKey is String && clientKey.isNotEmpty && clientKey != storedKey) {
      await _saveCredential(deviceId, clientKey);
    }
  }

  /// Requests the secondary "pointer input" socket and opens it. D-pad and
  /// other button presses travel over this socket rather than as SSAP
  /// requests.
  Future<void> _openPointerSocket() async {
    final response = await _sendRequest(
      'ssap://com.webos.service.networkinput/getPointerInputSocket',
    );
    final payload = response['payload'];
    final socketPath = payload is Map ? payload['socketPath'] : null;
    if (socketPath is! String || socketPath.isEmpty) {
      throw const ConnectionFailure('webOS did not return a pointer socket');
    }
    final pointer = await _connector(socketPath);
    _pointerSocket = pointer;
    // Drain incoming frames so the socket stays healthy; we only send on it.
    _pointerSub = pointer.messages.listen((_) {}, onError: (Object _) {});
  }

  /// Sends an SSAP `request` and completes with the matching response.
  Future<Map<String, dynamic>> _sendRequest(String uri) async {
    if (_socket == null) {
      throw const CommandFailure('Not connected to a webOS device');
    }
    final id = 'req_${_requestCounter++}';
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;
    _send({'id': id, 'type': 'request', 'uri': uri});
    try {
      return await completer.future.timeout(_requestTimeout);
    } on TimeoutException {
      _pendingRequests.remove(id);
      throw CommandFailure('webOS request timed out: $uri');
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
    final id = message['id'];
    final type = message['type'];

    // The register handshake emits an interim `response` (the TV is showing
    // its prompt) before the final `registered`. Ignore the interim — the
    // register completer resolves only on `registered` or `error`.
    if (id == _registerRequestId && type == 'response') return;

    if (id is! String) return;
    final completer = _pendingRequests.remove(id);
    if (completer == null || completer.isCompleted) return;
    if (type == 'error') {
      completer.completeError(
        ConnectionFailure(message['error']?.toString() ?? 'webOS SSAP error'),
      );
    } else {
      completer.complete(message);
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
    _pointerSub?.cancel();
    _pointerSub = null;
    _pointerSocket?.close();
    _pointerSocket = null;
    _socket?.close();
    _socket = null;
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(
          const ConnectionFailure('webOS connection closed'),
        );
      }
    }
    _pendingRequests.clear();
    _connectedDeviceId = null;
  }

  void _send(Map<String, dynamic> message) =>
      _socket?.send(jsonEncode(message));

  void _emit(Map<String, dynamic> event) {
    if (!_events.isClosed) _events.add(event);
  }
}

/// A discovered webOS TV and the host its SSAP socket lives on.
class _WebosDevice {
  const _WebosDevice({required this.id, required this.host});

  final String id;
  final String host;

  /// The `device` payload shape consumed by `DeviceDiscoveryNotifier`.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': 'LG webOS TV',
    'ipAddress': host,
    'modelName': '',
  };
}
