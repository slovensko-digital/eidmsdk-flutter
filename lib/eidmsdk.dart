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

/// Wrapper around the Slovak eID mSDK.
///
/// Every method here presents the native SDK's own UI and completes only when
/// the user is finished with it, so these futures are long-lived by nature.
///
/// The implementation behind them is resolved once, on first use: the real
/// method-channel implementation on a device, or [SimulatorEidmsdk] on an iOS
/// Simulator or Android emulator, where the SDK cannot work at all because it
/// needs NFC and a physical card. Use [ensureInitialized] to get that decision
/// out of the way early, and [isUsingFake] to ask which one you got.
///
/// A number of behaviours genuinely differ between Android and iOS, because the
/// two native SDKs do. Those differences are called out per method — the
/// cancellation ones in particular are easy to get wrong on one platform only.
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

  /// Clears the memoised platform and the [debugForceSimulator] override, so
  /// the next call resolves from scratch.
  @visibleForTesting
  static void resetForTesting() {
    _platformFuture = null;
    debugForceSimulator = null;
  }

  // TODO Cleanup code - put await _platform() on new line each time

  /// Sets the native SDK's log verbosity.
  ///
  /// Returns whether the level was actually applied, which is `false` on
  /// Android: its SDK exposes no log-level control, so the call is a logged
  /// no-op there. Returns `true` on iOS, and on a simulator, where the fake
  /// accepts any level.
  ///
  /// Unlike [getCertificates] and [signData], a native failure here is not
  /// translated — it surfaces as a raw [PlatformException].
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) async =>
      (await _platform()).setLogLevel(logLevel: logLevel);

  /// Presents the native SDK's tutorial on how to hold the card against the
  /// phone for NFC reading.
  ///
  /// Completes when the tutorial is dismissed on iOS, but **immediately** on
  /// Android, which launches the tutorial activity without waiting for it. Do
  /// not treat the returned future as "the user has finished reading".
  ///
  /// [language] is honoured on Android and ignored on iOS.
  ///
  /// On a simulator a placeholder screen stands in for the real tutorial.
  ///
  /// As with [setLogLevel], a native failure surfaces as a raw
  /// [PlatformException] rather than an [EidmsdkException].
  Future showTutorial({String? language}) async =>
      (await _platform()).showTutorial(language: language);

  /// Reads the signing certificates from the card.
  ///
  /// Presents the native SDK's card-reading UI, so the future stays pending
  /// while the user holds their card to the phone.
  ///
  /// [types] selects which certificates to read. **Android accepts exactly
  /// one** and fails if given none or several; iOS accepts a list.
  /// [language] is honoured on Android and ignored on iOS.
  ///
  /// Returns `null` when the user cancels — but on Android only. iOS reports a
  /// cancellation as an error instead, so there it arrives as an
  /// [EidmsdkException]. Handle both if you ship on both platforms.
  ///
  /// Throws [CertificateNotFoundException] when the card carries no signing
  /// certificate, and [EidmsdkException] for any other native failure.
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

  /// Signs [dataToSign] with the certificate at [certIndex].
  ///
  /// Presents the native SDK's PIN-and-sign UI, so the future stays pending
  /// while the user enters their KEP PIN and holds their card to the phone.
  ///
  /// The data is **hashed before it reaches the SDK**: both platforms compute
  /// SHA-256 over it and pass that digest on, so the signature is over the
  /// digest rather than over your bytes directly.
  ///
  /// [certIndex] comes from [Certificate.certIndex] in a [getCertificates]
  /// result. [signatureScheme] is an OID string — `1.2.840.113549.1.1.11` is
  /// sha256WithRSAEncryption. Set [isBase64Encoded] when [dataToSign] is
  /// base64 rather than plain text. [language] is honoured on Android and
  /// ignored on iOS.
  ///
  /// Returns the signature as base64, or `null` when the user cancels — on
  /// Android only, as with [getCertificates]; on iOS a cancellation arrives as
  /// an [EidmsdkException].
  ///
  /// Throws [EidmsdkException] for native failures, including an invalid,
  /// suspended or blocked KEP PIN.
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

  /// Translates a native [PlatformException] into this package's exception
  /// types.
  ///
  /// The SDKs report a missing signing certificate under different codes —
  /// `CertificateNotFoundException` on Android, `certificatesNotIssued` on iOS
  /// — and both map to [CertificateNotFoundException]. Everything else becomes
  /// an [EidmsdkException].
  ///
  /// Never returns: it always throws.
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
