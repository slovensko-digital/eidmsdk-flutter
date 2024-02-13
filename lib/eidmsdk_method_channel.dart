import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eidmsdk_platform_interface.dart';

/// An implementation of [EidmsdkPlatform] that uses method channels.
class MethodChannelEidmsdk extends EidmsdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('eidmsdk');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
