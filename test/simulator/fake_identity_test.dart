import 'dart:convert';

import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeIdentity', () {
    test('is a 2048-bit RSA key', () {
      expect(FakeIdentity.modulus.bitLength, 2048);
      expect(FakeIdentity.publicExponent, BigInt.from(65537));
    });

    test('primes are consistent with the modulus', () {
      expect(FakeIdentity.prime1 * FakeIdentity.prime2, FakeIdentity.modulus);
    });

    test('certificate is decodable DER', () {
      expect(FakeIdentity.certificateDer.length, greaterThan(500));
      // DER SEQUENCE tag.
      expect(FakeIdentity.certificateDer.first, 0x30);
      expect(
        base64Encode(FakeIdentity.certificateDer),
        FakeIdentity.certificateBase64,
      );
    });

    test('certificate and private key are a matched pair', () {
      // The modulus appears verbatim inside the certificate's
      // SubjectPublicKeyInfo, so this binds key to certificate without
      // needing an ASN.1 parser.
      final n = FakeIdentity.modulus;
      final nBytes = <int>[];
      var v = n;
      final byte = BigInt.from(256);
      while (v > BigInt.zero) {
        nBytes.insert(0, (v % byte).toInt());
        v = v ~/ byte;
      }
      expect(
        _indexOfSublist(FakeIdentity.certificateDer, nBytes),
        greaterThanOrEqualTo(0),
      );
    });
  });
}

int _indexOfSublist(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}
