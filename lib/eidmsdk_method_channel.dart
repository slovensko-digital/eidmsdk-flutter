import 'dart:convert' show jsonDecode;

import 'package:eidmsdk/types.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eidmsdk_platform_interface.dart';

/// An implementation of [EidmsdkPlatform] that uses method channels.
class MethodChannelEidmsdk extends EidmsdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('eidmsdk');

  /// Whether the host is an iOS Simulator or an Android emulator.
  ///
  /// Deliberately not on [EidmsdkPlatform]: this is a method-channel concern,
  /// and no other implementation needs to answer it.
  Future<bool> isSimulator() async {
    final result = await methodChannel.invokeMethod<bool>('isSimulator');

    return result ?? false;
  }

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
  Future showTutorial({EIDLanguage? language}) async {
    final arguments = {
      "language": language?.code,
    };

    return await methodChannel.invokeMethod<bool>('showTutorial', arguments);
  }

  @override
  Future<CertificatesInfo?> getCertificates({
    required EIDCertificateIndex type,
    EIDLanguage? language,
  }) async {
    // The wire value is this enum's own index; each native side maps it to
    // whatever its SDK expects. iOS indexes eIDCertificateIndex directly, while
    // Android shifts past the extra leading ALL member of EIDCertificateType.
    // Keeping that mapping native-side is what lets this be one plain value
    // rather than a platform-dependent offset computed here.
    final arguments = {
      "type": type.index,
      "language": language?.code,
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
    bool isBase64Encoded = false,
    EIDLanguage? language,
  }) async {
    final arguments = {
      "certIndex": certIndex,
      "signatureScheme": signatureScheme,
      "dataToSign": dataToSign,
      "isBase64Encoded": isBase64Encoded,
      "language": language?.code,
    };
    final signedData =
        await methodChannel.invokeMethod<String>('signData', arguments);
    if (signedData == null) {
      return null;
    }

    return signedData;
  }
}
