import 'eidmsdk_platform_interface.dart';

class Eidmsdk {
  Future<String?> getPlatformVersion() =>
      EidmsdkPlatform.instance.getPlatformVersion();

  Future<bool> setLogLevel({required EIDLogLevel logLevel}) =>
      EidmsdkPlatform.instance.setLogLevel(logLevel: logLevel);

  Future showTutorial() => EidmsdkPlatform.instance.showTutorial();

  Future<Map<String, dynamic>?> getCertificates(
          {required List<EIDCertificateIndex> types}) =>
      EidmsdkPlatform.instance.getCertificates(types: types);
}
