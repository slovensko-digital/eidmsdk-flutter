import 'package:flutter/services.dart';

import 'eidmsdk_platform_interface.dart';
import 'errors.dart';
import 'types.dart';

class Eidmsdk {
  Future<bool> setLogLevel({
    required EIDLogLevel logLevel,
  }) =>
      EidmsdkPlatform.instance.setLogLevel(
        logLevel: logLevel,
      );

  Future showTutorial({String? language}) =>
      EidmsdkPlatform.instance.showTutorial(
        language: language,
      );

  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
    String? language,
  }) async {
    try {
      return await EidmsdkPlatform.instance.getCertificates(
        types: types,
        language: language,
      );
    } on PlatformException catch (e) {
      switch (e.code) {
        case "CertificateNotFoundException":
        case "certificatesNotIssued":
          throw CertificateNotFoundException(e.message ?? '', e.details);
        default:
          throw EidmsdkException(e.message ?? '', e.details);
      }
    }
  }

  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false,
    String? language,
  }) =>
      EidmsdkPlatform.instance.signData(
        certIndex: certIndex,
        signatureScheme: signatureScheme,
        dataToSign: dataToSign,
        isBase64Encoded: isBase64Encoded,
        language: language,
      );
}
