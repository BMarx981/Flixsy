import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../errors/connect_failure.dart';
import 'pointer_control.dart';
import 'remote_channel.dart';
import 'text_input.dart';

const _methodChannel = MethodChannel('com.flixsy.app/connect_sdk');
const _eventChannel = EventChannel('com.flixsy.app/connect_sdk_events');

/// [RemoteChannel] backed by the native ConnectSDK bridge (MethodChannel +
/// EventChannel).
///
/// Retained as the legacy transport; the default channel is now the pure-Dart
/// `CompositeRemoteChannel`. Do not instantiate directly outside the channel
/// provider.
class ConnectChannel implements RemoteChannel {
  ConnectChannel() {
    _deviceEventStream = _eventChannel.receiveBroadcastStream().map((raw) {
      debugPrint('[ConnectChannel] raw native event: $raw');
      return _parseEvent(raw);
    });
  }

  late final Stream<Map<String, dynamic>> _deviceEventStream;

  @override
  Stream<Map<String, dynamic>> get deviceEvents => _deviceEventStream;

  @override
  Future<void> startDiscovery() => _invoke('startDiscovery');

  @override
  Future<void> stopDiscovery() => _invoke('stopDiscovery');

  @override
  Future<void> connectToDevice(String deviceId) =>
      _invoke('connectToDevice', {'deviceId': deviceId});

  @override
  Future<void> disconnect() => _invoke('disconnect');

  @override
  Future<void> sendKeyCommand(String key) =>
      _invoke('sendKeyCommand', {'key': key});

  @override
  Future<void> submitPairingCode(String code) =>
      _invoke('submitPairingCode', {'code': code});

  @override
  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async {
    try {
      final result = await _methodChannel.invokeMethod<List<dynamic>>(
        'getDiscoveredDevices',
      );
      return result?.cast<Map<String, dynamic>>() ?? [];
    } on PlatformException catch (e) {
      throw _mapError(e);
    }
  }

  @override
  PointerControl? get pointerControl => null;

  @override
  RemoteTextInput? get textInput => null;

  @override
  void dispose() {
    // The EventChannel broadcast stream owns no Dart-side resources; discovery
    // teardown happens natively via stopDiscovery(). Present so every
    // RemoteChannel implementation disposes uniformly.
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    debugPrint('[ConnectChannel] -> invokeMethod $method args=$args');
    try {
      await _methodChannel.invokeMethod<void>(method, args);
      debugPrint('[ConnectChannel] <- $method ok');
    } on PlatformException catch (e) {
      debugPrint(
        '[ConnectChannel] <- $method ERROR code=${e.code} msg=${e.message}',
      );
      throw _mapError(e);
    }
  }

  ConnectFailure _mapError(PlatformException e) {
    return switch (e.code) {
      'DISCOVERY_ERROR' => DiscoveryFailure(e.message ?? 'Discovery failed'),
      'CONNECTION_ERROR' => ConnectionFailure(e.message ?? 'Connection failed'),
      'COMMAND_ERROR' => CommandFailure(e.message ?? 'Command failed'),
      _ => UnknownFailure(e.message ?? 'Unknown error: ${e.code}'),
    };
  }

  Map<String, dynamic> _parseEvent(dynamic event) {
    if (event is Map) return Map<String, dynamic>.from(event);
    return const {};
  }
}
