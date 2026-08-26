// GENERATED FILE - DO NOT EDIT BY HAND.
//
// Regenerate with: tools/generate_fake_identity.sh
//
// This is a THROWAWAY, PUBLISHED keypair used only by SimulatorEidmsdk on
// simulators and emulators. It is self-signed, trusted by nobody, and its
// private key is committed on purpose so that fake signatures actually verify.
// Never treat a signature made with it as evidence of anything.

import 'dart:convert';
import 'dart:typed_data';

/// The fake signing identity: a self-signed RSA-2048 certificate for
/// `CN=Jozko Mrkvicka, L=Bratislava, C=SK`, plus its private key components.
class FakeIdentity {
  FakeIdentity._();

  static const String subjectCommonName = 'Jozko Mrkvicka';
  static const String subjectLocality = 'Bratislava';
  static const String subjectCountry = 'SK';

  static final BigInt modulus = BigInt.parse(
    '00a675c753380306217eda7803d878268cc2c7e1df9fd7c0385282687459141d'
    '979397f13dcc58b1ff2a1aac1ff4bd8f4fd7a4a5e38d7aa4fa4007d873d9b68a'
    '048c47fb794321fd2fc05f1f984bd0f40612ee73169d0a4089dbb25ff1e138e1'
    '3411451c3c48aac3ae5f2d6065a053f8b859fef53417c0d683362a13fe344255'
    'b430296a30aa0e932a5218d838e06f0d61d2a43e0aee24e6dd95e8bfff3bd117'
    '9235917950c8f87f66a57dc981bfcadd02fdde740e6f64843d7cf417ddadb283'
    'a68ea348e06400f8f2696294f6889badcce05820eeb9a43dbf6ec09acc446de1'
    '442acc3d4eb1ff6ac5fed6bbae3f9cfe25ed82f642d618603d73bf0a196ca4ae'
    'cb',
    radix: 16,
  );

  static final BigInt privateExponent = BigInt.parse(
    '3cfb56af13c3beb218fdcbb0c18ab094bc34a278ca4d0930bd9bbfa896f9b54b'
    '526b69e34c3056bc11c2fcde25dd4c234f5ceffb5aeba5a975f04549998b0f29'
    '9b5f55d396d6ca8f0f461316381df947f739d1a6ae06013112390fed318324fd'
    'b755f5a6b2662600cddd7660e94947c2d410eec3a6cb7ea625688e0f12a85f2a'
    '8baacd6b93bba3574b48441e7c3c24114dbf97f9245b0a1232b97d48401f0fb4'
    '220d32613e2c6312ac7ff62ea6be173f24c73c5df6a0761b79536b1a46cb9e4f'
    '749534282c2c95575a0d6550e0f6a55748490323eea0bd9bee3f847c47331f4f'
    'f17e93ba6165f2655671d7607505740b788030939287fa13ce1396ff4043c5',
    radix: 16,
  );

  static final BigInt prime1 = BigInt.parse(
    '00e76674778e7d70c037cf8a571f3494c5ef0784877cdb9b83eeb2f7e095cb68'
    'f662aaf6194d848b1961b9cfcd926ea1287bc54bea31bb4992984f541129be7f'
    '8d4261e68aaf5b86bab8a891e4e4eb6a08c75052440461bf16043af722fd1ff8'
    'ae99418e982df956b534ddc0ed92af3ecc1924d7d8502c15c3541b7f387a9c07'
    '4f',
    radix: 16,
  );

  static final BigInt prime2 = BigInt.parse(
    '00b827fb238088f178218dc5479fe5821de4811fa8d1ae2f795ed90c259906f9'
    'c2df764853b91d3a03c9e7492557dff5b1504fe223b277857bb0f68ec42f3920'
    'dc75afb1d07c90aa53f18da98bb92721983ace75f65081959b4ce2c8756375c2'
    '882191d73eb91a0c0c80b539a1a3d9213df5f945014d482f145ba9180891c841'
    'c5',
    radix: 16,
  );

  static final BigInt publicExponent = BigInt.from(65537);

  /// The certificate, DER-encoded and base64-wrapped. Returned verbatim as
  /// `Certificate.certData`, exactly as the real SDK returns a certificate.
  static const String certificateBase64 =
      'MIIDZzCCAk+gAwIBAgIUa8RSOn2uutdzYbEFJCS2DZImswUwDQYJKoZIhvcNAQEL'
      'BQAwOzELMAkGA1UEBhMCU0sxEzARBgNVBAcMCkJyYXRpc2xhdmExFzAVBgNVBAMM'
      'DkpvemtvIE1ya3ZpY2thMB4XDTIwMDEwMTAwMDAwMFoXDTQwMDEwMTAwMDAwMFow'
      'OzELMAkGA1UEBhMCU0sxEzARBgNVBAcMCkJyYXRpc2xhdmExFzAVBgNVBAMMDkpv'
      'emtvIE1ya3ZpY2thMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApnXH'
      'UzgDBiF+2ngD2HgmjMLH4d+f18A4UoJodFkUHZeTl/E9zFix/yoarB/0vY9P16Sl'
      '4416pPpAB9hz2baKBIxH+3lDIf0vwF8fmEvQ9AYS7nMWnQpAiduyX/HhOOE0EUUc'
      'PEiqw65fLWBloFP4uFn+9TQXwNaDNioT/jRCVbQwKWowqg6TKlIY2Djgbw1h0qQ+'
      'Cu4k5t2V6L//O9EXkjWReVDI+H9mpX3Jgb/K3QL93nQOb2SEPXz0F92tsoOmjqNI'
      '4GQA+PJpYpT2iJutzOBYIO65pD2/bsCazERt4UQqzD1Osf9qxf7Wu64/nP4l7YL2'
      'QtYYYD1zvwoZbKSuywIDAQABo2MwYTAdBgNVHQ4EFgQUvUG74UYp0PXUhuDbnHpQ'
      'a9FUL44wHwYDVR0jBBgwFoAUvUG74UYp0PXUhuDbnHpQa9FUL44wDwYDVR0TAQH/'
      'BAUwAwEB/zAOBgNVHQ8BAf8EBAMCBsAwDQYJKoZIhvcNAQELBQADggEBAA7Jc2D4'
      'sVRiDWokVCDp4h9j4IUcNt+6ze79eUVdRwiqVEFRy2po6ndhIm2OTIhyy9VqVkrv'
      'MeJRAXjOzlwNBD6suMpXvdantWX7ozPvbDvscG7ENDlHZziBp7EJKzonxrXEbCBl'
      'UjZPu7o0xSqXz8ISoJt5EYb6zjQ4gMj8LTUtW4U8CuwXLHxFlUo1/6PIGm18ZlYJ'
      'dyRmyB9DnyEZdRz3VMWtjBYFmi2u7vKYGsJ8hXjKlLFIEcKY0LQ+bdOSadlU30UX'
      'Z9SXXstHM4CLUKlBNrC0DS7L+2LusHRKFSqgc4zi+0LT0bxZX+vXb5qjd+VE3+aQ'
      '6DSZP045vGcqMZw=';

  static Uint8List get certificateDer =>
      Uint8List.fromList(base64Decode(certificateBase64));
}
