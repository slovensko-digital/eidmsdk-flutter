import 'package:eidmsdk/types.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eidmsdk/eidmsdk_platform_interface.dart';
import 'package:eidmsdk/eidmsdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEidmsdkPlatform
    with MockPlatformInterfaceMixin
    implements EidmsdkPlatform {
  @override
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) =>
      Future.value(true);

  @override
  Future showTutorial() => Future.value();

  @override
  Future<CertificatesInfo?> getCertificates(
          {required List<EIDCertificateIndex> types}) =>
      Future.value(const CertificatesInfo(
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

  @override
  Future<String?> signData(
          {required int certIndex,
          required String signatureScheme,
          required String dataToSign}) =>
      Future.value('');
}

void main() {
  final EidmsdkPlatform initialPlatform = EidmsdkPlatform.instance;

  test('$MethodChannelEidmsdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEidmsdk>());
  });
}
