import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'eidmsdk_method_channel.dart';

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
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
