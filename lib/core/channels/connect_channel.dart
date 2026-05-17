import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../errors/connect_failure.dart';

const _methodChannel = MethodChannel('com.flixsy.app/connect_sdk');
const _eventChannel = EventChannel('com.flixsy.app/connect_sdk_events');

class ConnectChannel {
  ConnectChannel() {
    _deviceEventStream = _eventChannel
        .receiveBroadcastStream()
        .map((raw) {
          debugPrint('[ConnectChannel] raw native event: $raw');
          return _parseEvent(raw);
        });
  }

  late final Stream<Map<String, dynamic>> _deviceEventStream;

  Stream<Map<String, dynamic>> get deviceEvents => _deviceEventStream;

  Future<void> startDiscovery() => _invoke('startDiscovery');

  Future<void> stopDiscovery() => _invoke('stopDiscovery');

  Future<void> connectToDevice(String deviceId) =>
      _invoke('connectToDevice', {'deviceId': deviceId});

  Future<void> disconnect() => _invoke('disconnect');

  Future<void> sendKeyCommand(String key) =>
      _invoke('sendKeyCommand', {'key': key});

  Future<List<Map<String, dynamic>>> getDiscoveredDevices() async {
    try {
      final result =
          await _methodChannel.invokeMethod<List<dynamic>>('getDiscoveredDevices');
      return result?.cast<Map<String, dynamic>>() ?? [];
    } on PlatformException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> _invoke(String method, [Map<String, dynamic>? args]) async {
    debugPrint('[ConnectChannel] -> invokeMethod $method args=$args');
    try {
      await _methodChannel.invokeMethod<void>(method, args);
      debugPrint('[ConnectChannel] <- $method ok');
    } on PlatformException catch (e) {
      debugPrint('[ConnectChannel] <- $method ERROR code=${e.code} msg=${e.message}');
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
