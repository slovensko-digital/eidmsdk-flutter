import 'dart:convert';

import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final platform = SimulatorEidmsdk();

  setUp(() {
    SimulatorEidmsdk.debugAssumeSimulator = true;
  });

  tearDown(() {
    SimulatorEidmsdk.debugAssumeSimulator = null;
  });

  group('SimulatorEidmsdk', () {
    test('setLogLevel reports success', () async {
      expect(await platform.setLogLevel(logLevel: EIDLogLevel.debug), isTrue);
    });

    testWidgets('showTutorial completes without throwing', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: Scaffold()));

      final result = platform.showTutorial();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(await result, isNull);
    });

    group('getCertificates', () {
      // getCertificates presents an interactive fake screen, so these tests,
      // which call the fake without any UI, short-circuit straight to
      // success. The two tests this made false — that the requested types
      // are honoured, and that certData is an obvious placeholder — are gone;
      // test/simulator/get_certificates_test.dart covers the real behaviour.
      setUp(() {
        SimulatorEidmsdk.autoRespond = const FakeProceed();
      });

      tearDown(() {
        SimulatorEidmsdk.autoRespond = null;
      });

      test(
        'returns the certificate regardless of the requested type',
        () async {
          final result = await platform.getCertificates(
            type: EIDCertificateIndex.qes,
          );

          expect(result, isNotNull);
          expect(result!.qscd, isTrue);
          expect(result.cardType, contains('SIMULATOR'));
          expect(result.certificates, hasLength(1));
          expect(result.certificates.single.slot, 'QES');
          expect(result.certificates.single.isQualified, isTrue);
        },
      );

      test('canned payload round-trips through the JSON codec', () async {
        final result = await platform.getCertificates(
          type: EIDCertificateIndex.qes,
        );

        // The real implementation receives this shape as a JSON string from
        // the native side, so the fake's payload has to survive the same
        // round trip.
        final restored = CertificatesInfo.fromJson(
          jsonDecode(jsonEncode(result!.toJson())) as Map<String, dynamic>,
        );

        expect(restored.qscd, result.qscd);
        expect(restored.cardType, result.cardType);
        expect(
          restored.certificates.map((e) => e.slot),
          result.certificates.map((e) => e.slot),
        );
      });
    });

    group('signData', () {
      // signData presents an interactive fake screen and produces a real
      // signature. The full behaviour -- including that the signature
      // actually verifies against the certificate -- is covered by
      // test/simulator/sign_data_test.dart.
      setUp(() {
        SimulatorEidmsdk.autoRespond = const FakeProceed();
      });

      tearDown(() {
        SimulatorEidmsdk.autoRespond = null;
      });

      test('returns a non-null signature', () async {
        final signature = await platform.signData(
          certIndex: 1,
          signatureScheme: '1.2.840.113549.1.1.11',
          dataToSign: 'hello world',
        );

        expect(signature, isNotNull);
      });
    });
  });
}
