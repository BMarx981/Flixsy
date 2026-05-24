import 'dart:async';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/channels/multicast_lock.dart';
import 'package:flixsy/core/channels/pointer_control.dart';
import 'package:flixsy/core/channels/text_input.dart';
import 'package:flixsy/core/channels/remote_channel.dart';

/// A [RemoteChannel] that fans across several per-vendor channels at once.
///
/// Discovery is broadcast to every sub-channel and their device / connection
/// events are merged into one [deviceEvents] stream. Each discovered device is
/// tagged with the sub-channel that surfaced it, so [connectToDevice],
/// [sendKeyCommand], and [disconnect] route to the right transport.
///
/// The composite owns its sub-channels — [dispose] disposes them all.
///
/// While discovery is running the composite holds the platform [MulticastLock]
/// so the sub-channels' mDNS / SSDP traffic is not dropped by the OS.
class CompositeRemoteChannel implements RemoteChannel {
  CompositeRemoteChannel(
    List<RemoteChannel> channels, {
    MulticastLock multicastLock = const NoopMulticastLock(),
  }) : _channels = List.unmodifiable(channels),
       _multicastLock = multicastLock {
    for (final channel in _channels) {
      _subscriptions.add(
        channel.deviceEvents.listen(
          (event) => _onChannelEvent(channel, event),
          onError: (Object error, StackTrace stackTrace) {
            if (!_events.isClosed) _events.addError(error, stackTrace);
          },
        ),
      );
    }
  }

  final List<RemoteChannel> _channels;
  final List<StreamSubscription<Map<String, dynamic>>> _subscriptions = [];

  /// Held only while discovery is active. See [_acquireMulticastLock].
  final MulticastLock _multicastLock;
  bool _multicastLockHeld = false;

  final StreamController<Map<String, dynamic>> _events =
      StreamController<Map<String, dynamic>>.broadcast();

  /// The sub-channel that surfaced each device, keyed by device `id`.
  final Map<String, RemoteChannel> _ownerByDeviceId = {};

  /// The sub-channel of the currently connected device, if any.
  RemoteChannel? _activeChannel;

  /// The sub-channel whose `connectToDevice` is currently in flight — the
  /// target for [submitPairingCode] during code-based pairing.
  RemoteChannel? _pairingChannel;

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _events.stream;

  @override
  Future<void> startDiscovery() async {
    if (_channels.isEmpty) return;
    await _acquireMulticastLock();
    final failures = <ConnectFailure>[];
    await Future.wait(
      _channels.map((channel) async {
        try {
          await channel.startDiscovery();
        } on ConnectFailure catch (failure) {
          failures.add(failure);
          _emit({'type': 'discoveryError', 'message': failure.message});
        }
      }),
    );
    // Surface a hard failure only when no channel could start at all — a
    // partial failure still leaves discovery running on the others.
    if (failures.length == _channels.length) {
      await _releaseMulticastLock();
      throw DiscoveryFailure(
        'No discovery channel could start: '
        '${failures.map((f) => f.message).join('; ')}',
      );
    }
  }

  @override
  Future<void> stopDiscovery() async {
    await Future.wait(_channels.map((channel) => channel.stopDiscovery()));
    await _releaseMulticastLock();
  }

  @override
  Future<void> connectToDevice(String deviceId) async {
    final owner = _ownerByDeviceId[deviceId];
    if (owner == null) {
      throw ConnectionFailure('Unknown device: $deviceId');
    }
    // Switching transports — drop the previous connection first.
    if (_activeChannel != null && !identical(_activeChannel, owner)) {
      await _activeChannel!.disconnect();
    }
    _pairingChannel = owner;
    try {
      await owner.connectToDevice(deviceId);
    } finally {
      _pairingChannel = null;
    }
    _activeChannel = owner;
  }

  @override
  Future<void> submitPairingCode(String code) async {
    final channel = _pairingChannel;
    if (channel == null) {
      throw const ConnectionFailure('No pairing is in progress');
    }
    await channel.submitPairingCode(code);
  }

  @override
  Future<void> disconnect() async {
    final active = _activeChannel;
    if (active == null) return;
    _activeChannel = null;
    await active.disconnect();
  }

  @override
  Future<void> sendKeyCommand(String key) async {
    final active = _activeChannel;
    if (active == null) {
      throw const CommandFailure('Not connected to a device');
    }
    await active.sendKeyCommand(key);
  }

  @override
  PointerControl? get pointerControl => _activeChannel?.pointerControl;

  @override
  RemoteTextInput? get textInput => _activeChannel?.textInput;

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async {
    final perChannel = await Future.wait(
      _channels.map((channel) => channel.getDiscoveredDevices()),
    );
    return [for (final devices in perChannel) ...devices];
  }

  @override
  void dispose() {
    // dispose() is synchronous; fire the release without awaiting it.
    if (_multicastLockHeld) {
      _multicastLockHeld = false;
      _multicastLock.release();
    }
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    for (final channel in _channels) {
      channel.dispose();
    }
    _events.close();
  }

  /// Acquires the multicast lock once for an active discovery session.
  /// Idempotent — a second [startDiscovery] does not stack a second hold.
  Future<void> _acquireMulticastLock() async {
    if (_multicastLockHeld) return;
    await _multicastLock.acquire();
    _multicastLockHeld = true;
  }

  /// Releases the lock if held. Safe to call when discovery never started.
  Future<void> _releaseMulticastLock() async {
    if (!_multicastLockHeld) return;
    _multicastLockHeld = false;
    await _multicastLock.release();
  }

  /// Records device ownership from a sub-channel's event, then re-emits it on
  /// the merged [deviceEvents] stream.
  void _onChannelEvent(RemoteChannel channel, Map<String, dynamic> event) {
    switch (event['type']) {
      case 'deviceFound':
      case 'deviceUpdated':
        final device = event['device'];
        if (device is Map) {
          final id = device['id'];
          if (id is String) _ownerByDeviceId[id] = channel;
        }
      case 'deviceLost':
        final id = event['deviceId'];
        if (id is String) _ownerByDeviceId.remove(id);
    }
    _emit(event);
  }

  void _emit(Map<String, dynamic> event) {
    if (!_events.isClosed) _events.add(event);
  }
}
