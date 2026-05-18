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
/// supply a fake; the production value is [defaultWebSocketConnector].
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
