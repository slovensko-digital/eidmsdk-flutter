import 'package:flutter_test/flutter_test.dart';
import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/eidmsdk_platform_interface.dart';
import 'package:eidmsdk/eidmsdk_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockEidmsdkPlatform
    with MockPlatformInterfaceMixin
    implements EidmsdkPlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<Map<String, dynamic>?> getCertificates({required List<EIDCertificateIndex> types}) =>
      Future.value({});

  @override
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) =>
      Future.value(true);
}

void main() {
  final EidmsdkPlatform initialPlatform = EidmsdkPlatform.instance;

  test('$MethodChannelEidmsdk is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelEidmsdk>());
  });

  test('getPlatformVersion', () async {
    Eidmsdk eidmsdkPlugin = Eidmsdk();
    MockEidmsdkPlatform fakePlatform = MockEidmsdkPlatform();
    EidmsdkPlatform.instance = fakePlatform;

    expect(await eidmsdkPlugin.getPlatformVersion(), '42');
  });
}
