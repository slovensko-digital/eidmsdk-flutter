import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'eidmsdk_method_channel.dart';

enum EIDLogLevel {
  verbose,
  debug,
  info,
  warning,
  error,
  none,
}

enum EIDCertificateIndex { qes, es, encryption }

abstract class EidmsdkPlatform extends PlatformInterface {
  /// Constructs a EidmsdkPlatform.
  EidmsdkPlatform() : super(token: _token);

  static final Object _token = Object();

  static EidmsdkPlatform _instance = MethodChannelEidmsdk();

  /// The default instance of [EidmsdkPlatform] to use.
  ///
  /// Defaults to [MethodChannelEidmsdk].
  static EidmsdkPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [EidmsdkPlatform] when
  /// they register themselves.
  static set instance(EidmsdkPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('getPlatformVersion() has not been implemented.');
  }

  Future<bool> setLogLevel({required EIDLogLevel logLevel}) {
    throw UnimplementedError('setLogLevel() has not been implemented.');
  }

  Future showTutorial() {
    throw UnimplementedError('showTutorial() has not been implemented.');
  }

  Future<Map<String, dynamic>?> getCertificates(
      {required List<EIDCertificateIndex> types}) {
    throw UnimplementedError('getCertificates() has not been implemented.');
  }
}
