import 'dart:convert';
import 'dart:typed_data';

import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:eidmsdk/src/simulator/fake_signer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

/// Verifies with the public key only, the way a relying party would.
bool _verifies(Uint8List data, String signatureBase64) {
  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')..init(
    false,
    PublicKeyParameter<RSAPublicKey>(
      RSAPublicKey(FakeIdentity.modulus, FakeIdentity.publicExponent),
    ),
  );

  return verifier.verifySignature(
    data,
    RSASignature(Uint8List.fromList(base64Decode(signatureBase64))),
  );
}

void main() {
  group('FakeSigner.decodeDataToSign', () {
    test('treats plain text as UTF-8 bytes', () {
      expect(
        FakeSigner.decodeDataToSign('hello world', isBase64Encoded: false),
        utf8.encode('hello world'),
      );
    });

    test('base64-decodes when told the input is encoded', () {
      final encoded = base64Encode(utf8.encode('hello world'));

      expect(
        FakeSigner.decodeDataToSign(encoded, isBase64Encoded: true),
        utf8.encode('hello world'),
      );
    });
  });

  group('FakeSigner.signBase64', () {
    test('produces a signature that verifies against the identity', () {
      final data = Uint8List.fromList(utf8.encode('hello world'));

      expect(_verifies(data, FakeSigner.signBase64(data)), isTrue);
    });

    test('produces a 2048-bit signature', () {
      final data = Uint8List.fromList(utf8.encode('hello world'));

      expect(base64Decode(FakeSigner.signBase64(data)).length, 256);
    });

    test('signature does not verify against different data', () {
      final signed = Uint8List.fromList(utf8.encode('hello world'));
      final tampered = Uint8List.fromList(utf8.encode('hello worlD'));

      expect(_verifies(tampered, FakeSigner.signBase64(signed)), isFalse);
    });

    test('is deterministic for the same input', () {
      final data = Uint8List.fromList(utf8.encode('hello world'));

      expect(FakeSigner.signBase64(data), FakeSigner.signBase64(data));
    });
  });
}
