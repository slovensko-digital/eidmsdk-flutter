import 'package:eidmsdk/eidmsdk.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEidmsdkPlatform
    with MockPlatformInterfaceMixin
    implements EidmsdkPlatform {
  final List<String> calls = [];

  @override
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) {
    calls.add('setLogLevel');

    return Future.value(true);
  }

  @override
  Future showTutorial({String? language}) {
    calls.add('showTutorial');

    return Future.value();
  }

  @override
  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
    String? language,
  }) {
    calls.add('getCertificates');

    return Future.value(const CertificatesInfo(
      qscd: true,
      cardType: "eID",
      certificates: [
        Certificate(
          slot: "QES",
          supportedSchemes: ["1.2.840.113549.1.1.11"],
          isQualified: true,
          certIndex: 1,
          certData: "data",
        )
      ],
    ));
  }

  @override
  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false,
    String? language,
  }) {
    calls.add('signData');

    return Future.value('');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final EidmsdkPlatform initialPlatform = EidmsdkPlatform.instance;

  tearDown(() {
    EidmsdkPlatform.instance = initialPlatform;
    Eidmsdk.resetForTesting();
  });

  test('$MethodChannelEidmsdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEidmsdk>());
  });

  test('an explicitly assigned platform is used as-is', () async {
    final mock = MockEidmsdkPlatform();
    EidmsdkPlatform.instance = mock;
    Eidmsdk.resetForTesting();

    final plugin = Eidmsdk();
    await plugin.setLogLevel(logLevel: EIDLogLevel.debug);
    await plugin.showTutorial();
    await plugin.getCertificates(types: [EIDCertificateIndex.qes]);
    await plugin.signData(
      certIndex: 1,
      signatureScheme: '1.2.840.113549.1.1.11',
      dataToSign: 'hello world',
    );

    expect(mock.calls,
        ['setLogLevel', 'showTutorial', 'getCertificates', 'signData']);
    expect(await Eidmsdk.isUsingFake(), isFalse);
  });

  group('simulator detection', () {
    test('substitutes the fake when a simulator is detected', () async {
      Eidmsdk.resetForTesting();
      Eidmsdk.debugForceSimulator = true;

      expect(await Eidmsdk.isUsingFake(), isTrue);
    });

    test('keeps the real implementation on a device', () async {
      Eidmsdk.resetForTesting();
      Eidmsdk.debugForceSimulator = false;

      expect(await Eidmsdk.isUsingFake(), isFalse);
    });

    test('fails closed to the real implementation when detection throws',
        () async {
      Eidmsdk.resetForTesting();
      // No mock handler is registered, so the channel call fails. A fake must
      // never stand in as a result of a detection failure.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('eidmsdk'),
        (call) async => throw PlatformException(code: 'boom'),
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('eidmsdk'), null));

      expect(await Eidmsdk.isUsingFake(), isFalse);
    });

    test('detection runs only once for concurrent first calls', () async {
      Eidmsdk.resetForTesting();
      var detections = 0;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('eidmsdk'),
        (call) async {
          if (call.method == 'isSimulator') detections++;

          return true;
        },
      );
      addTearDown(() => TestDefaultBinaryMessengerBinding
          .instance.defaultBinaryMessenger
          .setMockMethodCallHandler(const MethodChannel('eidmsdk'), null));

      await Future.wait([
        Eidmsdk.isUsingFake(),
        Eidmsdk.isUsingFake(),
        Eidmsdk.isUsingFake(),
      ]);

      expect(detections, 1);
    });
  });
}
