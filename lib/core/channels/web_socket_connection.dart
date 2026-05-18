import 'dart:io';

import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A bidirectional text-message socket — the surface the WebSocket-based
/// channels (webOS, Samsung) depend on.
///
/// Exposed as an interface so tests can substitute an in-memory fake for the
/// real network socket.
abstract interface class WebSocketConnection {
  /// Messages pushed from the remote end. Single-subscription.
  Stream<String> get messages;

  /// Sends a text [message] to the remote end.
  void send(String message);

  /// Closes the connection.
  Future<void> close();
}

/// Opens a [WebSocketConnection] to [url]. Injected into channels so tests can
/// supply a fake; the production values are [defaultWebSocketConnector] and
/// [insecureWebSocketConnector].
typedef WebSocketConnector = Future<WebSocketConnection> Function(String url);

/// [WebSocketConnection] backed by the `web_socket_channel` package.
class IoWebSocketConnection implements WebSocketConnection {
  IoWebSocketConnection(this._channel)
    : messages = _channel.stream.map((event) => event.toString());

  final WebSocketChannel _channel;

  @override
  final Stream<String> messages;

  @override
  void send(String message) => _channel.sink.add(message);

  @override
  Future<void> close() => _channel.sink.close();
}

/// Production [WebSocketConnector] — opens a real WebSocket and waits for the
/// handshake to complete before returning.
Future<WebSocketConnection> defaultWebSocketConnector(String url) async {
  final channel = WebSocketChannel.connect(Uri.parse(url));
  await channel.ready;
  return IoWebSocketConnection(channel);
}

/// [WebSocketConnector] that accepts self-signed TLS certificates.
///
/// Required for Samsung's `wss://<ip>:8002` endpoint: LAN TVs present
/// self-signed certificates that no certificate authority can validate.
Future<WebSocketConnection> insecureWebSocketConnector(String url) async {
  final httpClient = HttpClient()
    ..badCertificateCallback = (cert, host, port) => true;
  final channel = IOWebSocketChannel.connect(
    Uri.parse(url),
    customClient: httpClient,
  );
  await channel.ready;
  return IoWebSocketConnection(channel);
}
