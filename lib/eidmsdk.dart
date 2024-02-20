import 'eidmsdk_platform_interface.dart';

class Eidmsdk {
  Future<bool> setLogLevel({
    required EIDLogLevel logLevel,
  }) =>
      EidmsdkPlatform.instance.setLogLevel(
        logLevel: logLevel,
      );

  Future showTutorial() => EidmsdkPlatform.instance.showTutorial();

  Future<Map<String, dynamic>?> getCertificates({
    required List<EIDCertificateIndex> types,
  }) =>
      EidmsdkPlatform.instance.getCertificates(
        types: types,
      );

  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
  }) =>
      EidmsdkPlatform.instance.signData(
        certIndex: certIndex,
        signatureScheme: signatureScheme,
        dataToSign: dataToSign,
      );
}
