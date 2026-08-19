import 'dart:convert';

import 'package:eidmsdk/eidmsdk_method_channel.dart';
import 'package:eidmsdk/eidmsdk_platform_interface.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final MethodChannelEidmsdk platform = MethodChannelEidmsdk();
  const MethodChannel channel = MethodChannel('eidmsdk');
  final List<MethodCall> log = <MethodCall>[];

  setUp(() {
    log.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        log.add(methodCall);

        switch (methodCall.method) {
          case 'isSimulator':
            return true;
          case 'setLogLevel':
            return true;
          case 'getCertificates':
            return jsonEncode({
              'QSCD': true,
              'cardType': 'eID',
              'certificates': [
                {
                  'slot': 'QES',
                  'supportedSchemes': ['1.2.840.113549.1.1.11'],
                  'isQualified': true,
                  'certIndex': 1,
                  'certData': 'data',
                }
              ],
            });
          case 'signData':
            return 'c2lnbmF0dXJl';
          default:
            return null;
        }
      },
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('isSimulator forwards the native answer', () async {
    expect(await platform.isSimulator(), isTrue);
    expect(log.single.method, 'isSimulator');
  });

  test('isSimulator defaults to false when native returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    expect(await platform.isSimulator(), isFalse);
  });

  test('setLogLevel sends the enum index', () async {
    await platform.setLogLevel(logLevel: EIDLogLevel.warning);

    expect(log.single.arguments, {'logLevel': EIDLogLevel.warning.index});
  });

  test('getCertificates decodes the JSON string payload', () async {
    final result =
        await platform.getCertificates(types: [EIDCertificateIndex.qes]);

    expect(result, isNotNull);
    expect(result!.qscd, isTrue);
    expect(result.cardType, 'eID');
    expect(result.certificates.single.certIndex, 1);
  });

  test('getCertificates returns null when native returns null', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => null);

    expect(
      await platform.getCertificates(types: [EIDCertificateIndex.qes]),
      isNull,
    );
  });

  test('signData passes its arguments through and returns the signature',
      () async {
    final result = await platform.signData(
      certIndex: 1,
      signatureScheme: '1.2.840.113549.1.1.11',
      dataToSign: 'hello world',
    );

    expect(result, 'c2lnbmF0dXJl');
    expect(log.single.arguments, {
      'certIndex': 1,
      'signatureScheme': '1.2.840.113549.1.1.11',
      'dataToSign': 'hello world',
      'isBase64Encoded': false,
      'language': null,
    });
  });
}
