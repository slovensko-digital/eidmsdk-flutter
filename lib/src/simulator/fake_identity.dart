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
      '00b0ce12284270984fec8428aea736a31bb49b4108a51dfb460f7a9a0de63dc0'
      'db103dc606d020b353aaf862726ccaa6a98d72ccb2dcc1c711a71d079960f04f'
      '4371700b6de37cefe2a08be3cff76e73fe25573c396602f739984712dd108141'
      '420d315866a477ace4043a60afa4fed8c7aab8625da7322f283e9215ccb2c742'
      '2c86e6cca338e07ee45f052ad1bd7b7384caf9e56bf30977f8eba95869757f85'
      '77101ab9b8ed6f94c96e2a7cab4bd36e21eb46018a129b3816b0addab2c0351c'
      '470a85ae07c8d8eddf182f5f34bf339407aac94ab6bf66c96877f7c4fdfa49a2'
      'c195c77a08c523c0386ac19552de44e12b1b526142a1e75820458d8ed0010501'
      'a5',
      radix: 16);

  static final BigInt privateExponent = BigInt.parse(
      '094c9d69deacbb6620c386bc40f13fbcfa4fdc28cf3e7773e4e686e9ca3d5f42'
      '666549601c5c4bf24fa0c6d4cbe210c80437908aabcfc95fa551828fcfa87412'
      'd1099aa04a01cd40373f8458f0e3af5823b0a5eb42f14efd8983db7b231e1947'
      '97180c5541bb45adac8741849b8207f6e084d82fa2d6a1e255002c035b37ddc4'
      '1166dd69346f67f18f001f58393b32d598edaace66a38979703b1e3e96c49384'
      'd5b30a02acf28da069117025293d9158711314c5b104c0d575b1c8d02bfc02e2'
      '039c7f2cf006d1c8acfa25f3e0d894f1cb3794fe52a1cfad3094ce8bede4f01a'
      '636150c799fcb7e9ef89e6bcae43809b2afa3221bc97ca6065cca32123565735',
      radix: 16);

  static final BigInt prime1 = BigInt.parse(
      '00d6aff0140ef71a67693748153c200948c6e0bce72fde7606c04a988d66de26'
      '8ab98470c7de2d7f9391406a89e74787a2a77b81142d68dc9e0fd2c31dd33236'
      'a75db36044dee2d8358d4168011eb0e858624ab7cead766004e8de13ff04e909'
      'a7ababcb86086bdab3a5f6aed1649a7b55fc7c5b218e8face3baaa8634f1dc1c'
      '77',
      radix: 16);

  static final BigInt prime2 = BigInt.parse(
      '00d2d3f380b1678b7b2e917b08832eb37a320cd97e319bbcbb02b458343633e1'
      '156455fda7d5c213cd512779645a775be9ceb4e6be65596ed6d5a451bc868233'
      '8747558cdb423585eafd768c7a323065d86a551df13b97dca6e68370541c4da8'
      'f8624b7f816aed14553434b60a46a158c931bf4a3ccc3ab4f3994aca62e0db05'
      'c3',
      radix: 16);

  static final BigInt publicExponent = BigInt.from(65537);

  /// The certificate, DER-encoded and base64-wrapped. Returned verbatim as
  /// `Certificate.certData`, exactly as the real SDK returns a certificate.
  static const String certificateBase64 =
      'MIIDZzCCAk+gAwIBAgIULFz4cTCFJ0K4YZcUuNOmOsNyJakwDQYJKoZIhvcNAQEL'
      'BQAwOzELMAkGA1UEBhMCU0sxEzARBgNVBAcMCkJyYXRpc2xhdmExFzAVBgNVBAMM'
      'DkpvemtvIE1ya3ZpY2thMB4XDTIwMDEwMTAwMDAwMFoXDTQwMDEwMTAwMDAwMFow'
      'OzELMAkGA1UEBhMCU0sxEzARBgNVBAcMCkJyYXRpc2xhdmExFzAVBgNVBAMMDkpv'
      'emtvIE1ya3ZpY2thMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsM4S'
      'KEJwmE/shCiupzajG7SbQQilHftGD3qaDeY9wNsQPcYG0CCzU6r4YnJsyqapjXLM'
      'stzBxxGnHQeZYPBPQ3FwC23jfO/ioIvjz/duc/4lVzw5ZgL3OZhHEt0QgUFCDTFY'
      'ZqR3rOQEOmCvpP7Yx6q4Yl2nMi8oPpIVzLLHQiyG5syjOOB+5F8FKtG9e3OEyvnl'
      'a/MJd/jrqVhpdX+FdxAaubjtb5TJbip8q0vTbiHrRgGKEps4FrCt2rLANRxHCoWu'
      'B8jY7d8YL180vzOUB6rJSra/Zslod/fE/fpJosGVx3oIxSPAOGrBlVLeROErG1Jh'
      'QqHnWCBFjY7QAQUBpQIDAQABo2MwYTAdBgNVHQ4EFgQUEe4/cWM7Pj2UeAnjKi00'
      'HHTphMkwHwYDVR0jBBgwFoAUEe4/cWM7Pj2UeAnjKi00HHTphMkwDwYDVR0TAQH/'
      'BAUwAwEB/zAOBgNVHQ8BAf8EBAMCBsAwDQYJKoZIhvcNAQELBQADggEBAHTmkUVU'
      'JwiOHYxXtV+3il+7DT7mRNNgO5RfiDiwt5nBtBdJ2TABf/ujKuMQDQPaqmhBVqEo'
      'Jk2V4qOMGF9tgmGGe2Y9KSM58uyDrrGL/+j2KzSfdMmLpOwcptm6sfb2w6hLJ4BP'
      'aAqYzUNjoja79PwwoSJmGM/84yHc+uS07QjUI27140Qu4G+Ax8q0pT0Hz+umSuWS'
      'M06/0pPm45/u07Igvc7CGJexIRTcosoPeBELca1eoVbRz7EiGTV0ZaqCzG/S8v+R'
      'erilp/udu0Fz/mWIMrD7Dj497ju/BHGaYl+AlM+9pvXcgTcj26vFni/5D1yNdrBx'
      'Bmrl2WPuk6PZuFo=';

  static Uint8List get certificateDer =>
      Uint8List.fromList(base64Decode(certificateBase64));
}
