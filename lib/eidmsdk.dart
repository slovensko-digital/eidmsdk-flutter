import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'eidmsdk_method_channel.dart';
import 'eidmsdk_platform_interface.dart';
import 'eidmsdk_simulator.dart';
import 'errors.dart';
import 'src/simulator/fake_ui.dart';
import 'types.dart';

export 'eidmsdk_method_channel.dart' show MethodChannelEidmsdk;
export 'eidmsdk_platform_interface.dart'
    show EidmsdkPlatform, EIDLogLevel, EIDCertificateIndex;
export 'eidmsdk_simulator.dart' show SimulatorEidmsdk;
export 'errors.dart';
export 'src/simulator/fake_errors.dart' show FakeErrorCase;
export 'src/simulator/fake_outcome.dart'
    show FakeOutcome, FakeProceed, FakeError, FakeCancel;
export 'types.dart';

class Eidmsdk {
  /// Memoised platform resolution.
  ///
  /// The [EidmsdkPlatform.instance] getter is synchronous, but deciding whether
  /// this is a simulated host requires a round trip to the native side. Caching
  /// the [Future] rather than its value means concurrent first calls all await
  /// the same detection instead of racing or repeating it.
  static Future<EidmsdkPlatform>? _platformFuture;

  /// Forces the simulator decision, bypassing native detection. Lets both
  /// branches be tested off-simulator.
  @visibleForTesting
  static bool? debugForceSimulator;

  /// Optional escape hatch for the simulator fake's screens.
  ///
  /// The fake normally finds the host app's navigator by itself and needs no
  /// setup. Assign this to your app's `navigatorKey` only if it reports that it
  /// could not find one.
  static GlobalKey<NavigatorState>? get navigatorKey => FakeUi.navigatorKey;

  static set navigatorKey(GlobalKey<NavigatorState>? key) =>
      FakeUi.navigatorKey = key;

  static Future<EidmsdkPlatform> _platform() =>
      _platformFuture ??= _resolvePlatform();

  static Future<EidmsdkPlatform> _resolvePlatform() async {
    final current = EidmsdkPlatform.instance;

    // Anything explicitly assigned by the host app wins outright.
    if (current is! MethodChannelEidmsdk) {
      return current;
    }

    bool isSimulated;
    try {
      isSimulated = debugForceSimulator ?? await current.isSimulator();
    } catch (_) {
      // Fail closed. If detection cannot be completed for any reason, keep the
      // real implementation: a fake must never stand in on real hardware.
      isSimulated = false;
    }

    if (!isSimulated) {
      return current;
    }

    debugPrint(
      'eidmsdk: simulator/emulator detected, using SimulatorEidmsdk. '
      'THIS IS A FAKE - its certificate and signature are real cryptography '
      'from a committed, worthless keypair, and prove nothing.',
    );

    return SimulatorEidmsdk();
  }

  /// Resolves the platform implementation up front.
  ///
  /// Optional: every method below resolves on demand. Useful from `main()` when
  /// you want detection out of the way before the first frame.
  static Future<void> ensureInitialized() async {
    await _platform();
  }

  /// Whether calls are being served by the fake [SimulatorEidmsdk].
  static Future<bool> isUsingFake() async =>
      await _platform() is SimulatorEidmsdk;

  @visibleForTesting
  static void resetForTesting() {
    _platformFuture = null;
    debugForceSimulator = null;
  }

  // TODO Add missing method docs
  // TODO Cleanup code - put await _platform() on new line each time
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) async =>
      (await _platform()).setLogLevel(logLevel: logLevel);

  Future showTutorial({String? language}) async =>
      (await _platform()).showTutorial(language: language);

  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
    String? language,
  }) async {
    try {
      return await (await _platform()).getCertificates(
        types: types,
        language: language,
      );
    } on PlatformException catch (e) {
      decodeNativeError(e);
    }
  }

  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false,
    String? language,
  }) async {
    try {
      return await (await _platform()).signData(
        certIndex: certIndex,
        signatureScheme: signatureScheme,
        dataToSign: dataToSign,
        isBase64Encoded: isBase64Encoded,
        language: language,
      );
    } on PlatformException catch (e) {
      decodeNativeError(e);
    }
  }

  static Never decodeNativeError(PlatformException e) {
    switch (e.code) {
      case "CertificateNotFoundException":
      case "certificatesNotIssued":
        throw CertificateNotFoundException(e.message ?? '', e.details);

      default:
        throw EidmsdkException(e.message ?? '', e.details);
    }
  }
}
