import 'dart:isolate';
import 'dart:typed_data';

import 'package:basic_utils/basic_utils.dart';

import '../errors/connect_failure.dart';

/// A self-signed client identity — the certificate and key Flixsy presents to
/// an Android TV on both the pairing (6467) and remote-control (6466) TLS
/// connections. The same identity is reused for the life of a paired device
/// and persists between launches via the channel's credential callbacks.
class AndroidTvIdentity {
  const AndroidTvIdentity({
    required this.certificatePem,
    required this.privateKeyPem,
  });

  /// The self-signed X.509 certificate, PEM-encoded.
  final String certificatePem;

  /// The RSA private key, PEM-encoded.
  final String privateKeyPem;
}

/// The RSA public key of a certificate, reduced to the two numbers the Android
/// TV pairing hash consumes.
class RsaPublicNumbers {
  const RsaPublicNumbers({required this.modulus, required this.exponent});

  /// The RSA modulus.
  final BigInt modulus;

  /// The RSA public exponent.
  final BigInt exponent;
}

/// The crypto operations the Android TV channel needs, behind an interface so
/// tests can substitute a fast deterministic fake for the real,
/// RSA-keygen-backed implementation.
abstract interface class AndroidTvCrypto {
  /// Generates a fresh self-signed RSA-2048 client identity.
  Future<AndroidTvIdentity> generateIdentity();

  /// Extracts the RSA public key (modulus and exponent) from a PEM-encoded
  /// X.509 certificate.
  ///
  /// Throws [ConnectionFailure] if [certificatePem] is not a parseable RSA
  /// certificate.
  RsaPublicNumbers publicKeyOf(String certificatePem);
}

/// Production [AndroidTvCrypto], built on `basic_utils` / `pointycastle`.
class BasicUtilsAndroidTvCrypto implements AndroidTvCrypto {
  const BasicUtilsAndroidTvCrypto();

  @override
  Future<AndroidTvIdentity> generateIdentity() async {
    // RSA-2048 key generation is CPU-heavy; run it off the UI isolate.
    final pems = await Isolate.run(_generateIdentityPems);
    return AndroidTvIdentity(certificatePem: pems.$1, privateKeyPem: pems.$2);
  }

  @override
  RsaPublicNumbers publicKeyOf(String certificatePem) {
    try {
      final modulus = X509Utils.getModulusFromRSAX509Pem(certificatePem);
      final certificate = X509Utils.x509CertificateFromPem(certificatePem);
      final exponent =
          certificate.tbsCertificate?.subjectPublicKeyInfo.exponent;
      if (exponent == null) {
        throw const ConnectionFailure(
          'Android TV certificate carries no RSA public exponent',
        );
      }
      return RsaPublicNumbers(
        modulus: modulus,
        exponent: BigInt.from(exponent),
      );
    } on ConnectFailure {
      rethrow;
    } on Object catch (error) {
      throw ConnectionFailure('Could not read Android TV certificate: $error');
    }
  }
}

/// Generates an RSA-2048 key pair and a self-signed certificate, returning
/// `(certificatePem, privateKeyPem)`. Runs inside a background isolate.
(String, String) _generateIdentityPems() {
  final keyPair = CryptoUtils.generateRSAKeyPair();
  final publicKey = keyPair.publicKey as RSAPublicKey;
  final privateKey = keyPair.privateKey as RSAPrivateKey;
  final csr = X509Utils.generateRsaCsrPem(
    const {'CN': 'Flixsy'},
    privateKey,
    publicKey,
  );
  final certificate = X509Utils.generateSelfSignedCertificate(
    privateKey,
    csr,
    3650,
    serialNumber: '1000',
  );
  return (certificate, CryptoUtils.encodeRSAPrivateKeyToPem(privateKey));
}

/// Computes the Android TV pairing secret — the SHA-256 digest the client
/// returns to the TV to prove it saw the on-screen code.
///
/// The digest is `SHA-256` of, in order: the client modulus, the client
/// exponent (its uppercase hex prefixed with a literal `0`), the server
/// modulus, the server exponent (likewise `0`-prefixed), and the 2-byte nonce
/// — the last four hex characters of [pairingCode]. The first two characters
/// of [pairingCode] are a check byte the caller validates against the digest.
///
/// Throws [ConnectionFailure] if [pairingCode] is not exactly six hexadecimal
/// characters.
Uint8List computePairingSecret({
  required RsaPublicNumbers clientKey,
  required RsaPublicNumbers serverKey,
  required String pairingCode,
}) {
  final code = pairingCode.trim();
  if (code.length != 6 || !_hexPattern.hasMatch(code)) {
    throw const ConnectionFailure(
      'Pairing code must be six hexadecimal characters',
    );
  }
  final input = BytesBuilder()
    ..add(_hexToBytes(_modulusHex(clientKey.modulus)))
    ..add(_hexToBytes(_exponentHex(clientKey.exponent)))
    ..add(_hexToBytes(_modulusHex(serverKey.modulus)))
    ..add(_hexToBytes(_exponentHex(serverKey.exponent)))
    ..add(_hexToBytes(code.substring(2)));
  return CryptoUtils.getHashPlain(input.toBytes());
}

final RegExp _hexPattern = RegExp(r'^[0-9a-fA-F]+$');

/// Uppercase hex of [modulus], matching the reference `f"{n:X}"`.
String _modulusHex(BigInt modulus) => modulus.toRadixString(16).toUpperCase();

/// Uppercase hex of [exponent] with a literal `0` prepended, matching the
/// reference `f"0{e:X}"` — the prefix keeps the hex string an even length so
/// it decodes cleanly into bytes.
String _exponentHex(BigInt exponent) =>
    '0${exponent.toRadixString(16).toUpperCase()}';

/// Decodes an even-length hex [hex] string into bytes.
Uint8List _hexToBytes(String hex) {
  if (hex.length.isOdd) {
    throw FormatException('Hex string must have an even length', hex);
  }
  final bytes = Uint8List(hex.length ~/ 2);
  for (var i = 0; i < bytes.length; i++) {
    bytes[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return bytes;
}
