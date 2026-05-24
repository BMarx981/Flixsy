import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flixsy/core/channels/proto_codec.dart';

/// A TLS connection that exchanges varint-length-prefixed protobuf messages —
/// the transport surface the Android TV Remote v2 channel depends on.
///
/// Exposed as an interface so tests can drive an in-memory fake instead of a
/// real [SecureSocket].
abstract interface class ProtoSocket {
  /// One fully-reassembled protobuf message body per event, with the wire
  /// length prefix already stripped. Single-subscription.
  Stream<Uint8List> get messages;

  /// The peer's TLS certificate, PEM-encoded — needed to derive the Android TV
  /// pairing secret. `null` if the peer presented no certificate.
  String? get peerCertificatePem;

  /// Frames [message] with a varint length prefix and writes it to the peer.
  void send(List<int> message);

  /// Closes the connection.
  Future<void> close();
}

/// Opens a [ProtoSocket] to [host]:[port], presenting the given client
/// certificate. Injected into the Android TV channel so tests can supply a
/// fake; the production value is [secureProtoSocketConnector].
typedef ProtoSocketConnector =
    Future<ProtoSocket> Function({
      required String host,
      required int port,
      required String certificatePem,
      required String privateKeyPem,
    });

/// [ProtoSocket] backed by a real `dart:io` [SecureSocket].
class SecureProtoSocket implements ProtoSocket {
  SecureProtoSocket._(this._socket)
    : peerCertificatePem = _socket.peerCertificate?.pem {
    _socket.listen(
      (chunk) {
        for (final frame in _decoder.addChunk(chunk)) {
          if (!_messages.isClosed) _messages.add(frame);
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_messages.isClosed) _messages.addError(error, stackTrace);
      },
      onDone: () {
        if (!_messages.isClosed) _messages.close();
      },
    );
  }

  /// Connects to [host]:[port] over TLS, presenting the supplied self-signed
  /// client certificate. The TV's own self-signed certificate is accepted
  /// without validation — it is identified, not trusted, by its public key.
  ///
  /// Throws [ConnectionFailure] if the socket or TLS handshake fails.
  static Future<ProtoSocket> connect({
    required String host,
    required int port,
    required String certificatePem,
    required String privateKeyPem,
  }) async {
    final context = SecurityContext(withTrustedRoots: false)
      ..useCertificateChainBytes(utf8.encode(certificatePem))
      ..usePrivateKeyBytes(utf8.encode(privateKeyPem));
    try {
      final socket = await SecureSocket.connect(
        host,
        port,
        context: context,
        onBadCertificate: (_) => true,
      );
      return SecureProtoSocket._(socket);
    } on Object catch (error) {
      throw ConnectionFailure('Android TV TLS connection failed: $error');
    }
  }

  final SecureSocket _socket;
  final ProtoFrameDecoder _decoder = ProtoFrameDecoder();
  final StreamController<Uint8List> _messages = StreamController<Uint8List>();

  @override
  final String? peerCertificatePem;

  @override
  Stream<Uint8List> get messages => _messages.stream;

  @override
  void send(List<int> message) => _socket.add(frameMessage(message));

  @override
  Future<void> close() async {
    if (!_messages.isClosed) await _messages.close();
    _socket.destroy();
  }
}

/// Production [ProtoSocketConnector] — opens a real [SecureProtoSocket].
Future<ProtoSocket> secureProtoSocketConnector({
  required String host,
  required int port,
  required String certificatePem,
  required String privateKeyPem,
}) => SecureProtoSocket.connect(
  host: host,
  port: port,
  certificatePem: certificatePem,
  privateKeyPem: privateKeyPem,
);
