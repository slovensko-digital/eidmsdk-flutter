
import 'eidmsdk_platform_interface.dart';

class Eidmsdk {
  Future<String?> getPlatformVersion() {
    return EidmsdkPlatform.instance.getPlatformVersion();
  }
}
