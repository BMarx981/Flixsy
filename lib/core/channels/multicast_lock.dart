import 'dart:io' show Platform;

import 'package:flutter/services.dart';

/// Holds the platform Wi-Fi multicast lock for the duration of LAN discovery.
///
/// Android drops inbound multicast / broadcast packets to an app by default to
/// save power, which would silently starve mDNS (Android TV) and SSDP
/// discovery. The lock keeps those packets flowing while discovery runs.
///
/// Only Android has such a lock — every other platform delivers multicast
/// without one — so the production implementation is a no-op everywhere else.
abstract interface class MulticastLock {
  /// Acquires the lock. Safe to call when no lock is needed (non-Android).
  Future<void> acquire();

  /// Releases a previously acquired lock.
  Future<void> release();
}

/// A [MulticastLock] backed by the native `MulticastLockPlugin` MethodChannel.
///
/// No-ops on every non-Android platform: the channel is only registered by the
/// Android host, and no other platform needs the lock.
class PlatformMulticastLock implements MulticastLock {
  PlatformMulticastLock({MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(_channelName);

  static const _channelName = 'com.flixsy.app/multicast_lock';

  final MethodChannel _channel;

  @override
  Future<void> acquire() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('acquire');
  }

  @override
  Future<void> release() async {
    if (!Platform.isAndroid) return;
    await _channel.invokeMethod<void>('release');
  }
}

/// A [MulticastLock] that does nothing — the default for the composite channel
/// and the implementation used in tests.
class NoopMulticastLock implements MulticastLock {
  const NoopMulticastLock();

  @override
  Future<void> acquire() async {}

  @override
  Future<void> release() async {}
}
