import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_platform.dart';
import 'package:eidmsdk/src/simulator/fake_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  setUp(() {
    EidmsdkPlatform.instance = platform;
    Eidmsdk.resetForTesting();
  });

  tearDown(() {
    FakeUi.autoRespond = null;
    FakeHostPlatform.debugIsAndroidOverride = null;
    Eidmsdk.resetForTesting();
  });

  test('proceeding returns the hardcoded certificate', () async {
    FakeUi.autoRespond = const FakeProceed();

    final result = await platform.getCertificates(
      types: [EIDCertificateIndex.qes],
    );

    expect(result, isNotNull);
    expect(result!.qscd, isTrue);
    expect(result.cardType, 'eID (SIMULATOR)');
    expect(result.certificates, hasLength(1));
    expect(result.certificates.single.slot, 'QES');
    expect(result.certificates.single.certIndex, 1);
    expect(result.certificates.single.certData, FakeIdentity.certificateBase64);
  });

  test(
    'an error surfaces as the exception a real device would raise',
    () async {
      FakeUi.autoRespond = const FakeError(FakeErrorCase.certificatesNotIssued);

      // Through Eidmsdk, which applies the same mapping as for device errors.
      await expectLater(
        Eidmsdk().getCertificates(types: [EIDCertificateIndex.qes]),
        throwsA(isA<CertificateNotFoundException>()),
      );
    },
  );

  test('cancel returns null on Android', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = true;

    expect(
      await Eidmsdk().getCertificates(types: [EIDCertificateIndex.qes]),
      isNull,
    );
  });

  test('cancel throws on iOS, matching the real SDK', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = false;

    await expectLater(
      Eidmsdk().getCertificates(types: [EIDCertificateIndex.qes]),
      throwsA(isA<EidmsdkException>()),
    );
  });
}
