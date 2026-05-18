import 'package:flixsy/core/channels/android_tv_crypto.dart';
import 'package:flixsy/core/errors/connect_failure.dart';
import 'package:flutter_test/flutter_test.dart';

// Unit tests for `computePairingSecret` — the SHA-256 derivation that turns
// the code the TV displays into the secret returned to it. RSA key generation
// and certificate parsing are exercised only on real devices (Phase 8).

RsaPublicNumbers _key(String modulusHex) => RsaPublicNumbers(
  modulus: BigInt.parse(modulusHex, radix: 16),
  exponent: BigInt.from(65537),
);

void main() {
  group('computePairingSecret', () {
    final clientKey = _key('AABBCCDD11223344');
    final serverKey = _key('99887766FFEEDDCC');

    test('produces a 32-byte SHA-256 digest', () {
      final digest = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '1A2B3C',
      );
      expect(digest, hasLength(32));
    });

    test('is deterministic for the same inputs', () {
      final first = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '1A2B3C',
      );
      final second = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '1A2B3C',
      );
      expect(first, second);
    });

    test('changes when the code nonce changes', () {
      final a = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '001234',
      );
      final b = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '005678',
      );
      expect(a, isNot(b));
    });

    test('changes when the server key changes', () {
      final a = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '001234',
      );
      final b = computePairingSecret(
        clientKey: clientKey,
        serverKey: _key('1234567890ABCDEF'),
        pairingCode: '001234',
      );
      expect(a, isNot(b));
    });

    test('ignores the check-byte digits — only the nonce feeds the hash', () {
      final a = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: '00abcd',
      );
      final b = computePairingSecret(
        clientKey: clientKey,
        serverKey: serverKey,
        pairingCode: 'ffabcd',
      );
      expect(a, b);
    });

    test('rejects a code that is not six characters', () {
      expect(
        () => computePairingSecret(
          clientKey: clientKey,
          serverKey: serverKey,
          pairingCode: '1234',
        ),
        throwsA(isA<ConnectionFailure>()),
      );
    });

    test('rejects a non-hexadecimal code', () {
      expect(
        () => computePairingSecret(
          clientKey: clientKey,
          serverKey: serverKey,
          pairingCode: '12345Z',
        ),
        throwsA(isA<ConnectionFailure>()),
      );
    });
  });
}
