import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'fake_identity.dart';

/// Signs data with the throwaway [FakeIdentity] key.
///
/// Mirrors what the real plugin asks the SDK to do: an RSA PKCS#1 v1.5
/// signature over the SHA-256 digest of the data. The result verifies against
/// the certificate that `getCertificates` returns, so a host app can build a
/// real signature container from it — while the key itself is public and
/// trusted by nobody.
class FakeSigner {
  FakeSigner._();

  /// sha256WithRSAEncryption. The only scheme the fake identity supports.
  static const String supportedSignatureScheme = '1.2.840.113549.1.1.11';

  /// DER-encoded OID of SHA-256, as PointyCastle expects it for the PKCS#1
  /// DigestInfo wrapper.
  static const String _sha256DigestIdentifierHex = '0609608648016503040201';

  static Uint8List decodeDataToSign(
    String dataToSign, {
    required bool isBase64Encoded,
  }) => Uint8List.fromList(
    isBase64Encoded ? base64Decode(dataToSign) : utf8.encode(dataToSign),
  );

  static String signBase64(Uint8List data) {
    final key = RSAPrivateKey(
      FakeIdentity.modulus,
      FakeIdentity.privateExponent,
      FakeIdentity.prime1,
      FakeIdentity.prime2,
    );

    final signer = RSASigner(SHA256Digest(), _sha256DigestIdentifierHex)
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(key));

    // generateSignature digests its input itself and wraps the result in the
    // PKCS#1 DigestInfo structure. Pass the raw message: pre-hashing here
    // would hash twice and yield a signature that verifies against nothing.
    return base64Encode(signer.generateSignature(data).bytes);
  }
}
