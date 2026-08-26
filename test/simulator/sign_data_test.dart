import 'dart:convert';
import 'dart:typed_data';

import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_platform.dart';
import 'package:eidmsdk/src/simulator/fake_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

const _scheme = '1.2.840.113549.1.1.11';

bool _verifies(String text, String signatureBase64) {
  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')..init(
    false,
    PublicKeyParameter<RSAPublicKey>(
      RSAPublicKey(FakeIdentity.modulus, FakeIdentity.publicExponent),
    ),
  );

  return verifier.verifySignature(
    Uint8List.fromList(utf8.encode(text)),
    RSASignature(Uint8List.fromList(base64Decode(signatureBase64))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  setUp(() {
    EidmsdkPlatform.instance = platform;
    Eidmsdk.resetForTesting();
    SimulatorEidmsdk.debugAssumeSimulator = true;
  });

  tearDown(() {
    FakeUi.autoRespond = null;
    FakeHostPlatform.debugIsAndroidOverride = null;
    Eidmsdk.resetForTesting();
    SimulatorEidmsdk.debugAssumeSimulator = null;
  });

  test(
    'signing produces a signature that verifies against the certificate',
    () async {
      FakeUi.autoRespond = const FakeProceed();

      final signature = await platform.signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      );

      expect(signature, isNotNull);
      expect(_verifies('hello world', signature!), isTrue);
    },
  );

  test('honours isBase64Encoded', () async {
    FakeUi.autoRespond = const FakeProceed();

    final signature = await platform.signData(
      certIndex: 1,
      signatureScheme: _scheme,
      dataToSign: base64Encode(utf8.encode('hello world')),
      isBase64Encoded: true,
    );

    expect(_verifies('hello world', signature!), isTrue);
  });

  test('rejects an unsupported signature scheme', () async {
    FakeUi.autoRespond = const FakeProceed();

    await expectLater(
      Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.5',
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>()),
    );
  });

  test('a chosen error surfaces as an exception', () async {
    FakeUi.autoRespond = const FakeError(FakeErrorCase.signingFailed);

    await expectLater(
      Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>()),
    );
  });

  test('cancel returns null on Android', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = true;

    expect(
      await Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      ),
      isNull,
    );
  });

  test('cancel throws on iOS, matching the real SDK', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = false;

    await expectLater(
      Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>()),
    );
  });
}
