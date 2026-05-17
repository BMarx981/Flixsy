import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../errors/connect_failure.dart';

/// A single parsed response to an SSDP `M-SEARCH` query.
///
/// SSDP responses are HTTP-style: a status line followed by `Key: value`
/// headers. [parse] turns one raw datagram into an [SsdpResponse], or returns
/// `null` if the datagram is not a usable response.
class SsdpResponse {
  SsdpResponse._(this.headers);

  /// All response headers, with lower-cased keys.
  final Map<String, String> headers;

  /// Device-description URL (`LOCATION` header). Always present on a parsed
  /// response.
  String get location => headers['location']!;

  /// Unique Service Name (`USN` header) — stable per device, used as a device
  /// id. Always present on a parsed response.
  String get usn => headers['usn']!;

  /// The advertised search target (`ST`) or, for `NOTIFY` messages, the
  /// notification type (`NT`).
  String? get searchTarget => headers['st'] ?? headers['nt'];

  /// Free-form `SERVER` header (OS / product string), if any.
  String? get server => headers['server'];

  /// Host parsed from [location], or `null` if it cannot be parsed.
  String? get host => Uri.tryParse(location)?.host;

  /// Parses one raw SSDP datagram. Returns `null` when the text is not a
  /// usable response — i.e. it lacks a `LOCATION` or `USN` header.
  static SsdpResponse? parse(String raw) {
    final headers = <String, String>{};
    for (final line in const LineSplitter().convert(raw)) {
      final separator = line.indexOf(':');
      if (separator <= 0) continue;
      final key = line.substring(0, separator).trim().toLowerCase();
      headers[key] = line.substring(separator + 1).trim();
    }
    if (!headers.containsKey('location') || !headers.containsKey('usn')) {
      return null;
    }
    return SsdpResponse._(headers);
  }

  @override
  String toString() => 'SsdpResponse(usn: $usn, location: $location)';
}

/// The discovery surface a per-vendor channel depends on: a results stream
/// plus sweep lifecycle.
///
/// [SsdpDiscovery] is the production implementation; it is exposed as an
/// interface so channels (`RokuConnectChannel`, …) depend on the contract
/// rather than the concrete socket-backed class, letting tests substitute a
/// fake that feeds [responses] directly.
abstract interface class SsdpDiscoverer {
  /// Distinct devices discovered since the last [start].
  Stream<SsdpResponse> get responses;

  /// Begins an `M-SEARCH` sweep. Throws [DiscoveryFailure] if it cannot start.
  Future<void> start();

  /// Stops the sweep; the discoverer can be [start]ed again afterwards.
  Future<void> stop();

  /// Stops the sweep and closes [responses]. The instance is unusable after.
  Future<void> dispose();
}

/// Reusable SSDP discovery over UDP multicast.
///
/// Each per-vendor channel owns one [SsdpDiscovery] configured with that
/// vendor's [searchTarget] (e.g. `roku:ecp`,
/// `urn:lge-com:service:webos-second-screen:1`). Plain Dart — no Riverpod and
/// no platform channel.
///
/// Usage: subscribe to [responses] first, then call [start].
///
/// ```dart
/// final ssdp = SsdpDiscovery(searchTarget: 'roku:ecp');
/// ssdp.responses.listen((r) => print('found ${r.host}'));
/// await ssdp.start();
/// ```
class SsdpDiscovery implements SsdpDiscoverer {
  SsdpDiscovery({
    required this.searchTarget,
    this.mx = 3,
    this.queryAttempts = 3,
    this.queryInterval = const Duration(seconds: 1),
  });

  static final InternetAddress _multicastAddress = InternetAddress(
    '239.255.255.250',
  );
  static const int _multicastPort = 1900;

  /// The SSDP `ST` value to search for.
  final String searchTarget;

  /// `MX` header — the maximum number of seconds a device may wait before
  /// answering, so responses are spread out rather than all bursting at once.
  final int mx;

  /// How many times the `M-SEARCH` is sent. UDP is lossy, so the query is
  /// repeated rather than sent once.
  final int queryAttempts;

  /// Delay between repeated `M-SEARCH` sends.
  final Duration queryInterval;

  final StreamController<SsdpResponse> _controller =
      StreamController<SsdpResponse>.broadcast();
  final Set<String> _seenUsns = <String>{};

  RawDatagramSocket? _socket;
  Timer? _retryTimer;
  int _attemptsLeft = 0;

  /// Distinct devices discovered since the last [start]. Each `USN` is emitted
  /// at most once per discovery session.
  @override
  Stream<SsdpResponse> get responses => _controller.stream;

  /// Whether a discovery sweep is currently running.
  bool get isRunning => _socket != null;

  /// Binds the UDP socket and begins an `M-SEARCH` sweep.
  ///
  /// Subscribe to [responses] before calling this. A no-op if already running.
  /// Throws [DiscoveryFailure] if the socket cannot be bound.
  @override
  Future<void> start() async {
    if (_socket != null) return;
    _seenUsns.clear();
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      _socket = socket;
      socket.listen(_onSocketEvent);
    } on SocketException catch (e) {
      throw DiscoveryFailure('SSDP socket bind failed: ${e.message}');
    }
    _attemptsLeft = queryAttempts;
    _sendQuery();
  }

  /// Stops the sweep and releases the socket. Safe to call when not running;
  /// the instance can be [start]ed again afterwards.
  @override
  Future<void> stop() async {
    _retryTimer?.cancel();
    _retryTimer = null;
    _socket?.close();
    _socket = null;
    _seenUsns.clear();
  }

  /// Stops the sweep and closes [responses]. The instance is unusable after
  /// this — call once, from the owning channel's `dispose`.
  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  void _sendQuery() {
    final socket = _socket;
    if (socket == null || _attemptsLeft <= 0) return;
    _attemptsLeft--;

    final message =
        'M-SEARCH * HTTP/1.1\r\n'
        'HOST: ${_multicastAddress.address}:$_multicastPort\r\n'
        'MAN: "ssdp:discover"\r\n'
        'MX: $mx\r\n'
        'ST: $searchTarget\r\n'
        '\r\n';
    try {
      socket.send(utf8.encode(message), _multicastAddress, _multicastPort);
    } on SocketException catch (e) {
      if (!_controller.isClosed) {
        _controller.addError(
          DiscoveryFailure('SSDP send failed: ${e.message}'),
        );
      }
      return;
    }

    if (_attemptsLeft > 0) {
      _retryTimer = Timer(queryInterval, _sendQuery);
    }
  }

  void _onSocketEvent(RawSocketEvent event) {
    if (event != RawSocketEvent.read) return;
    final datagram = _socket?.receive();
    if (datagram == null) return;

    final response = SsdpResponse.parse(
      utf8.decode(datagram.data, allowMalformed: true),
    );
    if (response == null) return;
    if (!_seenUsns.add(response.usn)) return; // already surfaced this sweep
    if (!_controller.isClosed) _controller.add(response);
  }
}
