import 'dart:async';
import 'dart:convert';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/channels/pointer_control.dart';
import 'package:flixsy/core/channels/remote_channel.dart';
import 'package:flixsy/core/channels/ssdp_discovery.dart';
import 'package:flixsy/core/channels/text_input.dart';
import 'package:flixsy/core/channels/wake_on_lan.dart';
import 'package:flixsy/core/channels/web_socket_connection.dart';

/// Insecure SSAP WebSocket port (legacy webOS — `ws://`).
const int _webosInsecurePort = 3000;

/// Secure SSAP WebSocket port (modern webOS — `wss://` with a self-signed
/// cert). Required by webOS 4.x+; older TVs may not expose it.
const int _webosSecurePort = 3001;

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
class WebosConnectChannel
    implements RemoteChannel, PointerControl, RemoteTextInput {
  WebosConnectChannel({
    WebSocketConnector connector = tlsTolerantWebSocketConnector,
    SsdpDiscoverer? discovery,
    required Future<String?> Function(String deviceId) loadCredential,
    required Future<void> Function(String deviceId, String credential)
    saveCredential,
    Future<String?> Function(String deviceId)? loadMacAddress,
    Future<void> Function(String deviceId, String macAddress)? saveMacAddress,
    WakeOnLanSender wakeOnLan = sendWakeOnLan,
    Duration pairingTimeout = const Duration(seconds: 60),
    Duration requestTimeout = const Duration(seconds: 8),
  }) : _connector = connector,
       _ssdp = discovery ?? SsdpDiscovery(searchTarget: webosSearchTarget),
       _loadCredential = loadCredential,
       _saveCredential = saveCredential,
       _loadMacAddress = loadMacAddress,
       _saveMacAddress = saveMacAddress,
       _wakeOnLan = wakeOnLan,
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
  final Future<String?> Function(String deviceId)? _loadMacAddress;
  final Future<void> Function(String deviceId, String macAddress)?
  _saveMacAddress;
  final WakeOnLanSender _wakeOnLan;
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

  /// The deviceId of the most recently connected TV — survives disconnect so
  /// a Wake-on-LAN POWER press can target the TV the user was just on.
  String? _lastConnectedDeviceId;

  /// The device a `connectToDevice` is currently pairing with — used to tag
  /// the `pairingRequired` event surfaced while the TV shows its prompt.
  String? _pairingDeviceId;
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
    _pairingDeviceId = deviceId;
    try {
      final WebSocketConnection socket;
      try {
        socket = await _openSsapSocket(device.host);
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
      _lastConnectedDeviceId = deviceId;
      _emit({'type': 'connectionStateChanged', 'state': 'connected'});
      // Best-effort: capture the TV's MAC so we can wake it later via WoL.
      // Failures are silent — WoL is a bonus, not a requirement to connect.
      unawaited(_captureMacAddress(deviceId));
    } finally {
      _pairingDeviceId = null;
    }
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
    final upper = key.toUpperCase();
    // Power is two different operations depending on connection state:
    //  - Connected: SSAP `system/turnOff` to put the TV into standby.
    //  - Disconnected: Wake-on-LAN magic packet to bring it out of standby.
    // The pointer socket silently drops `name:POWER` on most LG firmware,
    // so neither half can use the standard button-frame path.
    if (upper == 'POWER' || upper == 'POWER_OFF' || upper == 'POWER_ON') {
      if (_connectedDeviceId != null && upper != 'POWER_ON') {
        try {
          await _sendRequest('ssap://system/turnOff');
        } on ConnectionFailure catch (failure) {
          throw CommandFailure(failure.message);
        }
        return;
      }
      await _wakeLastDevice();
      return;
    }
    if (_connectedDeviceId == null) {
      throw const CommandFailure('Not connected to a webOS device');
    }
    final pointer = _pointerSocket;
    if (pointer == null) {
      throw const CommandFailure('webOS pointer socket is not open');
    }
    final button = _buttonNames[upper];
    if (button == null) {
      throw CommandFailure('Unsupported webOS key: $key');
    }
    // The pointer input socket takes plain-text `field:value` frames.
    pointer.send('type:button\nname:$button\n\n');
  }

  /// Sends a Wake-on-LAN packet to the most recently connected TV. Throws
  /// [CommandFailure] when there is no remembered device or no persisted MAC.
  Future<void> _wakeLastDevice() async {
    final deviceId = _lastConnectedDeviceId;
    if (deviceId == null) {
      throw const CommandFailure(
        'Connect to the TV once so the app can remember its hardware address',
      );
    }
    final load = _loadMacAddress;
    final mac = load == null ? null : await load(deviceId);
    if (mac == null || mac.isEmpty) {
      throw const CommandFailure(
        'No saved hardware address for this TV — reconnect while it is on',
      );
    }
    await _wakeOnLan(mac);
  }

  @override
  Future<void> submitPairingCode(String code) async {
    throw const ConnectionFailure(
      'webOS pairing is confirmed on the TV, not by code',
    );
  }

  // --- PointerControl -----------------------------------------------------

  @override
  PointerControl? get pointerControl =>
      _connectedDeviceId != null && _pointerSocket != null ? this : null;

  // --- RemoteTextInput ----------------------------------------------------
  //
  // webOS's SSAP `com.webos.service.ime` service is the documented path for
  // pushing text into a focused TV field — `insertText` for text (with a
  // `replace` flag that doubles as a true one-shot clear), `deleteCharacters`
  // for backspace, `sendEnterKey` for submit. These all go over the main
  // SSAP socket, not the pointer-input socket (which only handles button
  // frames). The IME service is only available while the TV has a text
  // field focused; when it isn't, the SSAP call returns an `error` response
  // which we surface as a [CommandFailure].

  @override
  RemoteTextInput? get textInput => _connectedDeviceId == null ? null : this;

  @override
  Future<void> sendText(String text) async {
    if (text.isEmpty) return;
    await _imeRequest(
      'ssap://com.webos.service.ime/insertText',
      payload: {'text': text, 'replace': false},
    );
  }

  @override
  Future<void> sendBackspace() async {
    await _imeRequest(
      'ssap://com.webos.service.ime/deleteCharacters',
      payload: {'count': 1},
    );
  }

  @override
  Future<void> submit() async {
    await _imeRequest('ssap://com.webos.service.ime/sendEnterKey');
  }

  @override
  Future<void> clear({int knownLength = 0}) async {
    // `insertText` with replace:true wipes the field in one frame on webOS;
    // [knownLength] is ignored — see RemoteTextInput.clear's dartdoc.
    await _imeRequest(
      'ssap://com.webos.service.ime/insertText',
      payload: {'text': '', 'replace': true},
    );
  }

  /// Issues an SSAP IME request, remapping the SSAP-level [ConnectionFailure]
  /// (which `_sendRequest` uses for handshake errors) to a [CommandFailure]
  /// so the UI layer treats IME failures the same as any other
  /// post-connect command failure.
  Future<Map<String, dynamic>> _imeRequest(
    String uri, {
    Map<String, dynamic>? payload,
  }) async {
    if (_connectedDeviceId == null) {
      throw const CommandFailure('Not connected to a webOS device');
    }
    try {
      return await _sendRequest(uri, payload: payload);
    } on ConnectionFailure catch (failure) {
      throw CommandFailure(failure.message);
    }
  }

  /// webOS opens the pointer socket as part of [connectToDevice], so this is
  /// a sanity check rather than a setup call.
  @override
  Future<void> connectPointer() async {
    if (_connectedDeviceId == null || _pointerSocket == null) {
      throw const CommandFailure('webOS pointer socket is not open');
    }
  }

  @override
  Future<void> sendPointerMove(double dx, double dy) async {
    final pointer = _pointerSocket;
    if (_connectedDeviceId == null || pointer == null) {
      throw const CommandFailure('webOS pointer socket is not open');
    }
    // webOS pointer-input frame format: integer deltas, `down:0` for a move.
    pointer.send(
      'type:move\ndx:${dx.round()}\ndy:${dy.round()}\ndown:0\n\n',
    );
  }

  @override
  Future<void> sendPointerClick() async {
    final pointer = _pointerSocket;
    if (_connectedDeviceId == null || pointer == null) {
      throw const CommandFailure('webOS pointer socket is not open');
    }
    pointer.send('type:click\n\n');
  }

  @override
  Future<void> disconnectPointer() async {
    // The pointer socket is owned by the connection itself — torn down by
    // [disconnect]. Nothing session-scoped to release here.
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

  /// Opens the SSAP control socket, preferring `wss://:3001` (required by
  /// webOS 4.x+) and falling back to `ws://:3000` for older firmware.
  ///
  /// On newer TVs the insecure port often accepts the TCP connection then
  /// closes mid-handshake, so the secure attempt has to come first.
  Future<WebSocketConnection> _openSsapSocket(String host) async {
    try {
      return await _connector('wss://$host:$_webosSecurePort');
    } on Object {
      return _connector('ws://$host:$_webosInsecurePort');
    }
  }

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

  /// Best-effort: asks the TV for its wired/Wi-Fi MAC and persists it via
  /// [_saveMacAddress] so Wake-on-LAN can wake the TV later. Silent on
  /// failure — the caller fires this without awaiting.
  Future<void> _captureMacAddress(String deviceId) async {
    final save = _saveMacAddress;
    if (save == null) return;
    try {
      final response = await _sendRequest(
        'ssap://com.webos.service.connectionmanager/getInfo',
      );
      final payload = response['payload'];
      if (payload is! Map) return;
      // Prefer wired MAC — desks tend to wake more reliably over Ethernet.
      // Fall back to Wi-Fi MAC when the TV is wireless-only.
      final wiredInfo = payload['wiredInfo'];
      final wifiInfo = payload['wifiInfo'];
      final mac = (wiredInfo is Map ? wiredInfo['macAddress'] : null) ??
          (wifiInfo is Map ? wifiInfo['macAddress'] : null);
      if (mac is String && mac.isNotEmpty) {
        await save(deviceId, mac);
      }
    } on Object {
      // Older webOS firmware exposes the info under a different path; not
      // worth a fallback chain — WoL is a bonus capability.
    }
  }

  /// Sends an SSAP `request` and completes with the matching response.
  ///
  /// [payload] becomes the SSAP `payload` field when non-null — required for
  /// IME service calls (`insertText`, `deleteCharacters`).
  Future<Map<String, dynamic>> _sendRequest(
    String uri, {
    Map<String, dynamic>? payload,
  }) async {
    if (_socket == null) {
      throw const CommandFailure('Not connected to a webOS device');
    }
    final id = 'req_${_requestCounter++}';
    final completer = Completer<Map<String, dynamic>>();
    _pendingRequests[id] = completer;
    _send({
      'id': id,
      'type': 'request',
      'uri': uri,
      'payload': ?payload,
    });
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
    // its on-screen prompt) before the final `registered`. Surface it as a
    // pairing cue; the register completer resolves only on `registered` or
    // `error`.
    if (id == _registerRequestId && type == 'response') {
      final pairingDeviceId = _pairingDeviceId;
      if (pairingDeviceId != null) {
        _emit({
          'type': 'pairingRequired',
          'deviceId': pairingDeviceId,
          'kind': 'confirmOnTv',
        });
      }
      return;
    }

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
    'vendor': 'webos',
  };
}
