import 'dart:convert';

import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final platform = SimulatorEidmsdk();

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

    test('getCertificates returns a certificate for the requested type',
        () async {
      final result =
          await platform.getCertificates(types: [EIDCertificateIndex.qes]);

      expect(result, isNotNull);
      expect(result!.qscd, isTrue);
      expect(result.cardType, contains('SIMULATOR'));
      expect(result.certificates, hasLength(1));
      expect(result.certificates.single.slot, 'QES');
      expect(result.certificates.single.isQualified, isTrue);
    });

    test('getCertificates honours the requested types', () async {
      final result = await platform.getCertificates(types: [
        EIDCertificateIndex.es,
        EIDCertificateIndex.encryption,
      ]);

      expect(
        result!.certificates.map((e) => e.slot),
        ['ES', 'Encryption'],
      );
    });

    test('certData is decodable but obviously not a real certificate',
        () async {
      final result =
          await platform.getCertificates(types: [EIDCertificateIndex.qes]);
      final decoded =
          utf8.decode(base64Decode(result!.certificates.single.certData));

      expect(decoded, contains('FAKE'));
    });

    test('canned payload round-trips through the JSON codec', () async {
      final result =
          await platform.getCertificates(types: EIDCertificateIndex.values);

      // The real implementation receives this shape as a JSON string from the
      // native side, so the fake's payload has to survive the same round trip.
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

    test('signData throws rather than returning a fake signature', () async {
      expect(
        () => platform.signData(
          certIndex: 1,
          signatureScheme: '1.2.840.113549.1.1.11',
          dataToSign: 'hello world',
        ),
        throwsA(
          isA<EidmsdkException>().having(
            (e) => e.message,
            'message',
            contains('not implemented'),
          ),
        ),
      );
    });
  });
}
