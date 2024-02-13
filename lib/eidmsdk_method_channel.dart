import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eidmsdk_platform_interface.dart';

/// An implementation of [EidmsdkPlatform] that uses method channels.
class MethodChannelEidmsdk extends EidmsdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('eidmsdk');

  @override
  Future<String?> getPlatformVersion() async =>
      await methodChannel.invokeMethod<String>('getPlatformVersion');

  @override
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) async {
    final arguments = {
      "logLevel": logLevel.index,
    };
    final result =
        await methodChannel.invokeMethod<bool>('setLogLevel', arguments);

    return result ?? false;
  }

  @override
  Future<Map<String, dynamic>?> getCertificates(
      {required List<EIDCertificateIndex> types}) async {
    final arguments = {
      "types": types.map((e) => e.index).toList(),
    };
    final jsonData =
        await methodChannel.invokeMethod<String>('getCertificates', arguments);
    if (jsonData == null) {
      return null;
    }

    return jsonDecode(jsonData);
  }
}
