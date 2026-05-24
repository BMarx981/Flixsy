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
/// supply a fake; production uses [tlsTolerantWebSocketConnector].
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

/// Production [WebSocketConnector]. For `wss://` URLs it accepts self-signed
/// TLS certs (LAN TVs from LG and Samsung present certs no CA can validate);
/// for `ws://` it uses the default client.
Future<WebSocketConnection> tlsTolerantWebSocketConnector(String url) async {
  final uri = Uri.parse(url);
  final WebSocketChannel channel;
  if (uri.scheme == 'wss') {
    final httpClient = HttpClient()
      ..badCertificateCallback = (cert, host, port) => true;
    channel = IOWebSocketChannel.connect(uri, customClient: httpClient);
  } else {
    channel = WebSocketChannel.connect(uri);
  }
  await channel.ready;
  return IoWebSocketConnection(channel);
}
