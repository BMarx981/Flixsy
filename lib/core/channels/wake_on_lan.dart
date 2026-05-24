import 'dart:io';
import 'dart:typed_data';

import 'package:flixsy/core/errors/connect_failure.dart';

/// Sends a Wake-on-LAN magic packet to wake a device from standby.
///
/// Used by [WebosConnectChannel] when the user presses POWER while
/// disconnected — webOS keeps its NIC alive in standby when "Mobile TV On" is
/// enabled and the TV powers back up on receiving its own magic packet.
typedef WakeOnLanSender = Future<void> Function(String macAddress);

/// Default [WakeOnLanSender] — broadcasts a magic packet over UDP.
///
/// Sends to both the global broadcast (`255.255.255.255`) and the per-subnet
/// broadcast derived from each non-loopback IPv4 interface. Some routers drop
/// the global broadcast; the subnet broadcast tends to get through.
Future<void> sendWakeOnLan(String macAddress) async {
  final bytes = _macBytes(macAddress);
  if (bytes == null) {
    throw CommandFailure('Invalid MAC address: $macAddress');
  }

  // Magic packet: 6 bytes of 0xFF followed by the MAC repeated 16 times.
  final packet = Uint8List(6 + 6 * 16);
  for (var i = 0; i < 6; i++) {
    packet[i] = 0xFF;
  }
  for (var i = 0; i < 16; i++) {
    packet.setRange(6 + i * 6, 6 + (i + 1) * 6, bytes);
  }

  final targets = await _broadcastAddresses();
  RawDatagramSocket? socket;
  try {
    socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    socket.broadcastEnabled = true;
    for (final target in targets) {
      // Port 9 (Discard) is the conventional WoL port; some TVs also listen
      // on port 7 (Echo). Sending to 9 covers webOS.
      socket.send(packet, target, 9);
    }
  } on Object catch (error) {
    throw CommandFailure('Wake-on-LAN failed: $error');
  } finally {
    socket?.close();
  }
}

/// Parses a MAC string in `aa:bb:cc:dd:ee:ff` or `aa-bb-cc-dd-ee-ff` form
/// into 6 raw bytes. Returns `null` if [mac] is not a valid MAC.
Uint8List? _macBytes(String mac) {
  final parts = mac.split(RegExp('[:-]'));
  if (parts.length != 6) return null;
  final bytes = Uint8List(6);
  for (var i = 0; i < 6; i++) {
    final value = int.tryParse(parts[i], radix: 16);
    if (value == null || value < 0 || value > 0xFF) return null;
    bytes[i] = value;
  }
  return bytes;
}

/// Collects every IPv4 broadcast target worth trying — the global
/// `255.255.255.255` plus the directed broadcast for each non-loopback
/// interface that has a `/24` we can derive. Best-effort: a missing or
/// non-standard netmask just skips the interface.
Future<List<InternetAddress>> _broadcastAddresses() async {
  final addresses = <InternetAddress>{InternetAddress('255.255.255.255')};
  try {
    final interfaces = await NetworkInterface.list(
      includeLoopback: false,
      type: InternetAddressType.IPv4,
    );
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        // Best-effort /24 broadcast — Flutter doesn't expose netmasks, so
        // assume the common case. If wrong, the global broadcast above is
        // the fallback.
        final parts = addr.address.split('.');
        if (parts.length != 4) continue;
        addresses.add(InternetAddress('${parts[0]}.${parts[1]}.${parts[2]}.255'));
      }
    }
  } on Object {
    // Interface enumeration not supported on this platform — fall back to
    // the global broadcast that's already in the set.
  }
  return addresses.toList(growable: false);
}
