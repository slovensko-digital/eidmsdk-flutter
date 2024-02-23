import 'dart:convert';

import 'package:eidmsdk/types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eidmsdk_platform_interface.dart';

/// An implementation of [EidmsdkPlatform] that uses method channels.
class MethodChannelEidmsdk extends EidmsdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('eidmsdk');

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
  Future showTutorial() async =>
      await methodChannel.invokeMethod<bool>('showTutorial', {});

  @override
  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
  }) async {
    final arguments = {
      "types": types.map((e) => e.index).toList(),
    };
    final jsonData =
        await methodChannel.invokeMethod<String>('getCertificates', arguments);
    if (jsonData == null) {
      return null;
    }

    return CertificatesInfo.fromJson(jsonDecode(jsonData));
  }

  @override
  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false
  }) async {
    final arguments = {
      "certIndex": certIndex,
      "signatureScheme": signatureScheme,
      "dataToSign": dataToSign,
      "isBase64Encoded": isBase64Encoded,
    };
    final signedData =
        await methodChannel.invokeMethod<String>('signData', arguments);
    if (signedData == null) {
      return null;
    }

    return signedData;
  }
}
