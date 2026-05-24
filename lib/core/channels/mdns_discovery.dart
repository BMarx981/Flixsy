import 'dart:async';

import 'package:multicast_dns/multicast_dns.dart';

import 'package:flixsy/core/errors/connect_failure.dart';

/// A single service instance resolved via mDNS / DNS-SD.
class MdnsService {
  MdnsService({
    required this.name,
    required this.host,
    required this.port,
    required this.address,
  });

  /// The fully-qualified instance name from the PTR record.
  final String name;

  /// The target hostname from the SRV record.
  final String host;

  /// The TCP port from the SRV record.
  final int port;

  /// The resolved IPv4 address.
  final String address;

  @override
  String toString() => 'MdnsService(name: $name, address: $address:$port)';
}

/// The discovery surface a per-vendor channel depends on: a results stream
/// plus sweep lifecycle.
///
/// [MdnsDiscovery] is the production implementation; it is exposed as an
/// interface so the Android TV channel depends on the contract rather than the
/// concrete socket-backed class, letting tests substitute a fake that feeds
/// [services] directly. This mirrors `SsdpDiscoverer` for the SSDP channels.
abstract interface class MdnsDiscoverer {
  /// Distinct services discovered since the last [start].
  Stream<MdnsService> get services;

  /// Begins a browse sweep. Throws [DiscoveryFailure] if it cannot start.
  Future<void> start();

  /// Stops the sweep; the discoverer can be [start]ed again afterwards.
  Future<void> stop();

  /// Stops the sweep and closes [services]. The instance is unusable after.
  Future<void> dispose();
}

/// Reusable mDNS / DNS-SD discovery, wrapping the `multicast_dns` package.
///
/// Finds devices that advertise over Bonjour rather than SSDP — notably
/// Android TV, which publishes `_androidtvremote2._tcp`. Plain Dart — no
/// Riverpod and no platform channel.
///
/// [start] runs a single timed browse sweep (PTR → SRV → A records); call it
/// again to re-scan. Subscribe to [services] before calling [start].
class MdnsDiscovery implements MdnsDiscoverer {
  MdnsDiscovery({required String serviceType})
    : _query = serviceType.endsWith('.local')
          ? serviceType
          : '$serviceType.local';

  /// The DNS-SD service name to browse — `serviceType` with a `.local` suffix.
  final String _query;

  final StreamController<MdnsService> _controller =
      StreamController<MdnsService>.broadcast();
  final Set<String> _seenNames = <String>{};

  MDnsClient? _client;

  /// Distinct services discovered since the last [start]. Each instance name
  /// is emitted at most once per discovery session.
  @override
  Stream<MdnsService> get services => _controller.stream;

  /// Whether a browse sweep is currently running.
  bool get isRunning => _client != null;

  /// Starts the mDNS client and begins browsing for the service type.
  ///
  /// Subscribe to [services] before calling this. A no-op if already running.
  /// Throws [DiscoveryFailure] if the client cannot be started.
  @override
  Future<void> start() async {
    if (_client != null) return;
    _seenNames.clear();
    final client = MDnsClient();
    try {
      await client.start();
    } on Object catch (error) {
      // `OSError` (e.g. "Address already in use" from a stale multicast bind)
      // is not a SocketException, so we have to catch broadly here — otherwise
      // it propagates as an unhandled exception and kills the isolate.
      // Release whatever the client did manage to bind before surfacing.
      try {
        client.stop();
      } on Object {
        // Best-effort cleanup — the original failure is what matters.
      }
      throw DiscoveryFailure('mDNS client failed to start: $error');
    }
    _client = client;
    unawaited(_browse(client));
  }

  /// Stops the mDNS client. Safe to call when not running; the instance can be
  /// [start]ed again afterwards.
  @override
  Future<void> stop() async {
    _client?.stop();
    _client = null;
    _seenNames.clear();
  }

  /// Stops browsing and closes [services]. The instance is unusable after
  /// this — call once, from the owning channel's `dispose`.
  @override
  Future<void> dispose() async {
    await stop();
    await _controller.close();
  }

  Future<void> _browse(MDnsClient client) async {
    try {
      await for (final ptr in client.lookup<PtrResourceRecord>(
        ResourceRecordQuery.serverPointer(_query),
      )) {
        if (!identical(_client, client)) return; // stopped mid-browse
        await for (final srv in client.lookup<SrvResourceRecord>(
          ResourceRecordQuery.service(ptr.domainName),
        )) {
          await for (final ip in client.lookup<IPAddressResourceRecord>(
            ResourceRecordQuery.addressIPv4(srv.target),
          )) {
            if (!identical(_client, client)) return;
            if (!_seenNames.add(ptr.domainName)) continue;
            if (_controller.isClosed) return;
            _controller.add(
              MdnsService(
                name: ptr.domainName,
                host: srv.target,
                port: srv.port,
                address: ip.address.address,
              ),
            );
          }
        }
      }
    } on Object catch (e) {
      if (!_controller.isClosed) {
        _controller.addError(DiscoveryFailure('mDNS lookup failed: $e'));
      }
    }
  }
}
