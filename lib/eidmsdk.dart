import 'eidmsdk_platform_interface.dart';

class Eidmsdk {
  Future<String?> getPlatformVersion() {
    return EidmsdkPlatform.instance.getPlatformVersion();
  }

  Future<bool> setLogLevel({required EIDLogLevel logLevel}) {
    return EidmsdkPlatform.instance.setLogLevel(logLevel: logLevel);
  }

  Future<Map<String, dynamic>?> getCertificates(
      {required List<EIDCertificateIndex> types}) {
    return EidmsdkPlatform.instance.getCertificates(types: types);
  }
}
