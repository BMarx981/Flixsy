import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:xml/xml.dart';

import '../errors/connect_failure.dart';
import 'pointer_control.dart';
import 'remote_channel.dart';
import 'ssdp_discovery.dart';

/// Default port for Roku's External Control Protocol (ECP).
const int _rokuEcpPort = 8060;

/// Outcome of one HTTP request issued by the Roku channel.
class RokuHttpResponse {
  const RokuHttpResponse({required this.statusCode, this.body = ''});

  /// HTTP status code of the response.
  final int statusCode;

  /// Decoded response body. Empty for `POST /keypress` (Roku returns none).
  final String body;

  /// Whether the status code is in the 2xx success range.
  bool get isSuccess => statusCode >= 200 && statusCode < 300;
}

/// The minimal HTTP surface the Roku ECP channel needs: issue a request and
/// get back a status code and body.
///
/// Injected so tests can stub the network without a live Roku. The production
/// implementation, [IoRokuHttpClient], wraps `dart:io`'s [HttpClient].
abstract interface class RokuHttpClient {
  /// Issues [method] (`GET` or `POST`) to [url].
  ///
  /// Completes with the [RokuHttpResponse] for any HTTP status code. Throws
  /// on a transport-level failure (host unreachable, timeout) — the channel
  /// maps that to a [ConnectFailure].
  Future<RokuHttpResponse> send(String method, Uri url);

  /// Releases the underlying client and its pooled connections.
  void close();
}

/// [RokuHttpClient] backed by `dart:io`'s [HttpClient].
class IoRokuHttpClient implements RokuHttpClient {
  IoRokuHttpClient({Duration timeout = const Duration(seconds: 4)})
    : _timeout = timeout {
    _client.connectionTimeout = timeout;
  }

  final Duration _timeout;
  final HttpClient _client = HttpClient();

  @override
  Future<RokuHttpResponse> send(String method, Uri url) async {
    final request = await _client.openUrl(method, url);
    final response = await request.close().timeout(_timeout);
    // Draining the body frees the socket even when the caller ignores it.
    final body = await response
        .transform(utf8.decoder)
        .join()
        .timeout(_timeout);
    return RokuHttpResponse(statusCode: response.statusCode, body: body);
  }

  @override
  void close() => _client.close(force: true);
}

/// [RemoteChannel] for Roku TVs and players over ECP.
///
/// Roku needs no pairing: discovery is SSDP (`ST: roku:ecp`), control is
/// `POST /keypress/<key>` on port 8060, and [connectToDevice] is a liveness
/// check against `/query/device-info`. The HTTP transport and the SSDP
/// discoverer are both injectable for testing.
class RokuConnectChannel implements RemoteChannel {
  RokuConnectChannel({RokuHttpClient? httpClient, SsdpDiscoverer? discovery})
    : _http = httpClient ?? IoRokuHttpClient(),
      _ssdp = discovery ?? SsdpDiscovery(searchTarget: rokuSearchTarget) {
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

  /// SSDP `ST` value Roku devices answer to.
  static const String rokuSearchTarget = 'roku:ecp';

  /// Maps the app's generic key vocabulary to Roku ECP key names. Lookup is
  /// case-insensitive — keys are upper-cased before matching.
  static const Map<String, String> _rokuKeys = {
    'UP': 'Up',
    'DOWN': 'Down',
    'LEFT': 'Left',
    'RIGHT': 'Right',
    'OK': 'Select',
    'SELECT': 'Select',
    'ENTER': 'Select',
    'HOME': 'Home',
    'BACK': 'Back',
    'PLAY': 'Play',
    'PAUSE': 'Play',
    'PLAY_PAUSE': 'Play',
    'FAST_FORWARD': 'Fwd',
    'NEXT': 'Fwd',
    'REWIND': 'Rev',
    'PREVIOUS': 'Rev',
    'INSTANT_REPLAY': 'InstantReplay',
    'INFO': 'Info',
    'VOLUME_UP': 'VolumeUp',
    'VOLUME_DOWN': 'VolumeDown',
    'MUTE': 'VolumeMute',
    'POWER': 'Power',
    'POWER_OFF': 'PowerOff',
    'POWER_ON': 'PowerOn',
    'CHANNEL_UP': 'ChannelUp',
    'CHANNEL_DOWN': 'ChannelDown',
  };

  final RokuHttpClient _http;
  final SsdpDiscoverer _ssdp;
  late final StreamSubscription<SsdpResponse> _ssdpSub;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Devices discovered this session, keyed by their `id` (the SSDP `USN`).
  final Map<String, _RokuDevice> _devices = {};

  String? _connectedDeviceId;

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
      throw ConnectionFailure('Unknown Roku device: $deviceId');
    }
    final RokuHttpResponse response;
    try {
      response = await _http.send('GET', device.endpoint('/query/device-info'));
    } on Object catch (error) {
      throw ConnectionFailure('Roku unreachable: $error');
    }
    if (!response.isSuccess) {
      throw ConnectionFailure(
        'Roku rejected connection (HTTP ${response.statusCode})',
      );
    }
    _connectedDeviceId = deviceId;
    _emit({'type': 'connectionStateChanged', 'state': 'connected'});
  }

  @override
  Future<void> disconnect() async {
    if (_connectedDeviceId == null) return;
    _connectedDeviceId = null;
    _emit({'type': 'connectionStateChanged', 'state': 'disconnected'});
  }

  @override
  Future<void> sendKeyCommand(String key) async {
    final deviceId = _connectedDeviceId;
    if (deviceId == null) {
      throw const CommandFailure('Not connected to a Roku device');
    }
    final device = _devices[deviceId];
    if (device == null) {
      throw const CommandFailure('Connected Roku device is no longer known');
    }
    final rokuKey = _rokuKeys[key.toUpperCase()];
    if (rokuKey == null) {
      throw CommandFailure('Unsupported Roku key: $key');
    }
    final RokuHttpResponse response;
    try {
      response = await _http.send(
        'POST',
        device.endpoint('/keypress/$rokuKey'),
      );
    } on Object catch (error) {
      throw CommandFailure('Roku key send failed: $error');
    }
    if (!response.isSuccess) {
      throw CommandFailure(
        'Roku rejected key $key (HTTP ${response.statusCode})',
      );
    }
  }

  @override
  Future<void> submitPairingCode(String code) async {
    throw const ConnectionFailure('Roku devices do not require pairing');
  }

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async =>
      _devices.values.map((device) => device.toMap()).toList(growable: false);

  @override
  PointerControl? get pointerControl => null;

  @override
  void dispose() {
    _ssdpSub.cancel();
    _ssdp.dispose();
    _http.close();
    _events.close();
  }

  /// Handles one SSDP hit: resolves the device's friendly name/model via
  /// `/query/device-info` (best-effort) and emits a `deviceFound` event.
  Future<void> _onSsdpResponse(SsdpResponse response) async {
    final location = Uri.tryParse(response.location);
    final host = location?.host;
    if (location == null || host == null || host.isEmpty) return;
    final port = location.hasPort ? location.port : _rokuEcpPort;

    final device = await _describe(response.usn, host, port);
    _devices[device.id] = device;
    _emit({'type': 'deviceFound', 'device': device.toMap()});
  }

  /// Builds a [_RokuDevice], enriching it with the friendly name and model
  /// from `/query/device-info`. Falls back to defaults if that fetch fails —
  /// description is best-effort and never blocks discovery.
  Future<_RokuDevice> _describe(String id, String host, int port) async {
    var name = 'Roku';
    var model = '';
    try {
      final response = await _http.send(
        'GET',
        Uri(scheme: 'http', host: host, port: port, path: '/query/device-info'),
      );
      if (response.isSuccess) {
        final info = _parseDeviceInfo(response.body);
        name = info.name ?? name;
        model = info.model ?? model;
      }
    } on Object catch (error) {
      debugPrint('[RokuConnectChannel] device-info fetch failed: $error');
    }
    return _RokuDevice(
      id: id,
      name: name,
      ipAddress: host,
      modelName: model,
      host: host,
      port: port,
    );
  }

  /// Extracts the friendly device name and model from a Roku
  /// `/query/device-info` XML body. Returns `null` fields on a parse error.
  ({String? name, String? model}) _parseDeviceInfo(String xmlBody) {
    try {
      final document = XmlDocument.parse(xmlBody);
      String? text(String tag) {
        for (final element in document.findAllElements(tag)) {
          final value = element.innerText.trim();
          if (value.isNotEmpty) return value;
        }
        return null;
      }

      final name =
          text('user-device-name') ??
          text('friendly-device-name') ??
          text('default-device-name');
      final model = text('friendly-model-name') ?? text('model-name');
      return (name: name, model: model);
    } on XmlException {
      return (name: null, model: null);
    }
  }

  void _emit(Map<String, dynamic> event) {
    if (!_events.isClosed) _events.add(event);
  }
}

/// A discovered Roku device plus the address its ECP endpoints live at.
class _RokuDevice {
  const _RokuDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.modelName,
    required this.host,
    required this.port,
  });

  final String id;
  final String name;
  final String ipAddress;
  final String modelName;
  final String host;
  final int port;

  /// Builds the URL for an ECP [path] (e.g. `/keypress/Home`) on this device.
  Uri endpoint(String path) =>
      Uri(scheme: 'http', host: host, port: port, path: path);

  /// The `device` payload shape consumed by `DeviceDiscoveryNotifier`.
  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'ipAddress': ipAddress,
    'modelName': modelName,
  };
}
