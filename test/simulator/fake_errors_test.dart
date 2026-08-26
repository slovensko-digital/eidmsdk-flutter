import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeErrorCase', () {
    test('every case carries a non-empty code and label', () {
      for (final c in FakeErrorCase.values) {
        expect(c.code, isNotEmpty, reason: '${c.name} code');
        expect(c.label, isNotEmpty, reason: '${c.name} label');
      }
    });

    test('codes are unique', () {
      final codes = FakeErrorCase.values.map((c) => c.code).toList();

      expect(codes.toSet().length, codes.length);
    });

    test('codes match expected literals exactly', () {
      // Pin each code to its expected string. This catches transcription errors
      // that the uniqueness test cannot, since any string is "unique" if written
      // consistently. These strings must match what the native SDKs report.
      const expectedCodes = <FakeErrorCase, String>{
        FakeErrorCase.certificatesNotIssued: 'certificatesNotIssued',
        FakeErrorCase.cancelledByUser: 'cancelledByUser',
        FakeErrorCase.certificateReadFailed: 'certificateReadFailed',
        FakeErrorCase.signingFailed: 'signingFailed',
        FakeErrorCase.unsupportedSignatureScheme: 'unsupportedSignatureScheme',
        FakeErrorCase.kepPinInvalid: 'kepPinInvalid',
        FakeErrorCase.kepPinBlocked: 'kepPinBlocked',
        FakeErrorCase.tagConnectionLost: 'tagConnectionLost',
        FakeErrorCase.sessionTimeout: 'sessionTimeout',
        FakeErrorCase.nfcNotSupported: 'nfcNotSupported',
      };

      for (final MapEntry(key: c, value: expected) in expectedCodes.entries) {
        expect(c.code, expected, reason: 'code for ${c.name}');
      }
    });

    test('certificatesNotIssued maps to CertificateNotFoundException', () {
      // Routed through the real mapping the plugin uses for device errors, so
      // the fake cannot drift from it.
      expect(
        () => Eidmsdk.decodeNativeError(
          PlatformException(code: FakeErrorCase.certificatesNotIssued.code),
        ),
        throwsA(isA<CertificateNotFoundException>()),
      );
    });

    test(
      'other cases map to EidmsdkException, not CertificateNotFoundException',
      () {
        for (final c in FakeErrorCase.values.where(
          (c) => c != FakeErrorCase.certificatesNotIssued,
        )) {
          expect(
            () => Eidmsdk.decodeNativeError(PlatformException(code: c.code)),
            throwsA(
              allOf(
                isA<EidmsdkException>(),
                isNot(isA<CertificateNotFoundException>()),
              ),
            ),
            reason: c.name,
          );
        }
      },
    );
  });

  group('FakeOutcome', () {
    test('is exhaustively switchable', () {
      String describe(FakeOutcome outcome) => switch (outcome) {
        FakeProceed() => 'proceed',
        FakeError(error: final e) => 'error:${e.code}',
        FakeCancel() => 'cancel',
      };

      expect(describe(const FakeProceed()), 'proceed');
      expect(describe(const FakeCancel()), 'cancel');
      expect(
        describe(const FakeError(FakeErrorCase.signingFailed)),
        'error:signingFailed',
      );
    });
  });

  group('FakeHostPlatform', () {
    tearDown(() => FakeHostPlatform.debugIsAndroidOverride = null);

    test('honours the test override in both directions', () {
      FakeHostPlatform.debugIsAndroidOverride = true;
      expect(FakeHostPlatform.isAndroid, isTrue);

      FakeHostPlatform.debugIsAndroidOverride = false;
      expect(FakeHostPlatform.isAndroid, isFalse);
    });
  });
}
