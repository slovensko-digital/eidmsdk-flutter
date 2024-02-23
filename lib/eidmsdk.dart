import 'package:eidmsdk/types.dart';

import 'eidmsdk_platform_interface.dart';

class Eidmsdk {
  Future<bool> setLogLevel({
    required EIDLogLevel logLevel,
  }) =>
      EidmsdkPlatform.instance.setLogLevel(
        logLevel: logLevel,
      );

  Future showTutorial() => EidmsdkPlatform.instance.showTutorial();

  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
  }) =>
      EidmsdkPlatform.instance.getCertificates(
        types: types,
      );

  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false
  }) =>
      EidmsdkPlatform.instance.signData(
        certIndex: certIndex,
        signatureScheme: signatureScheme,
        dataToSign: dataToSign,
        isBase64Encoded: isBase64Encoded,
      );
}
