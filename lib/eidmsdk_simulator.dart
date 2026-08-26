import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'eidmsdk_method_channel.dart';
import 'eidmsdk_platform_interface.dart';
import 'errors.dart';
import 'src/simulator/fake_errors.dart';
import 'src/simulator/fake_identity.dart';
import 'src/simulator/fake_outcome.dart';
import 'src/simulator/fake_platform.dart';
import 'src/simulator/fake_signer.dart';
import 'src/simulator/fake_ui.dart';
import 'src/simulator/screens/certificates_screen.dart';
import 'src/simulator/screens/sign_screen.dart';
import 'src/simulator/screens/tutorial_screen.dart';
import 'types.dart';

/// A fake [EidmsdkPlatform] for the iOS Simulator and the Android emulator.
///
/// The eID mSDK communicates with a Slovak eID card over NFC, so it can never
/// function on a simulator. Rather than fail to build (iOS) or fail at run time
/// (Android), [Eidmsdk] substitutes this implementation automatically when it
/// detects a simulated host. See `Eidmsdk.isUsingFake`.
///
/// `getCertificates` and `signData` are interactive: each presents a screen so
/// every branch — success, a chosen error code, cancellation — is reachable by
/// hand. The certificate `getCertificates` returns and the signature
/// `signData` produces are genuine RSA cryptography, and the signature
/// verifies against the certificate — both backed by a throwaway keypair
/// whose private key is committed to this repository. They prove nothing
/// about who signed what and must never be trusted as evidence.
///
/// [PlatformException] codes are reported using the iOS `eIDError` vocabulary
/// on both platforms, including cancellation's platform asymmetry: an Android
/// emulator completes with `null`, an iOS Simulator throws. This is exact on
/// iOS; a real Android device reports Throwable class names instead (see
/// [FakeErrorCase]), so a host that inspects `PlatformException.code` directly
/// will see iOS-shaped codes on an emulator.
///
/// What it does *not* emulate, because it replaces [MethodChannelEidmsdk]
/// wholesale rather than sitting behind it:
///
///  * the Android-only `+1` offset applied to [EIDCertificateIndex] values,
///  * the *real* tutorial UI — `showTutorial` presents a screen, but a fake
///    placeholder rather than the native SDK's actual tutorial content.
class SimulatorEidmsdk extends EidmsdkPlatform {
  /// Verbatim from the native implementations, so a host app sees the same
  /// message it would see from a real device.
  static const String _certificatesErrorMessage =
      'Chyba pri načítaní podpisového certifikátu.';

  /// Verbatim from the native implementations, so a host app sees the same
  /// message it would see from a real device.
  static const String _signErrorMessage = 'Chyba pri podpisovaní.';

  /// When set, the fake screens resolve to this outcome immediately and nothing
  /// renders. Set it in tests so that calls into the plugin cannot hang waiting
  /// for a tap that never comes.
  static FakeOutcome? get autoRespond => FakeUi.autoRespond;

  static set autoRespond(FakeOutcome? outcome) => FakeUi.autoRespond = outcome;

  /// Overrides the simulator check performed by [_assertSimulated]. Tests only.
  @visibleForTesting
  static bool? debugAssumeSimulator;

  /// Refuses to run anywhere a real card could be used.
  ///
  /// Auto-detection already prevents this in the common case — exactly on
  /// iOS, since detection there is compile-time, and heuristically on
  /// Android, tuned to avoid false positives that would run the fake on real
  /// hardware. But a host can assign [SimulatorEidmsdk] directly, bypassing
  /// auto-detection entirely; [debugAssumeSimulator] is `@visibleForTesting`,
  /// an analyzer hint rather than an enforced guard, and does not stop that.
  /// Checking again here, at call time, closes that direct-assignment case:
  /// it is what stands between a false positive on Android and a genuine
  /// verifying signature produced silently on a real device. Before the
  /// interactive fake and real signing existed, a false positive cost a
  /// placeholder and a throw; now it costs a verifying signature, which is
  /// why this check exists.
  Future<void> _assertSimulated() async {
    final simulated =
        debugAssumeSimulator ?? await MethodChannelEidmsdk().isSimulator();
    if (!simulated) {
      throw EidmsdkException(
        'SimulatorEidmsdk was used on real hardware. It produces fake '
        'certificates and signatures, so it refuses to run outside a '
        'simulator or emulator. Use MethodChannelEidmsdk instead.',
      );
    }
  }

  @override
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) async {
    await _assertSimulated();

    return true;
  }

  @override
  Future showTutorial({String? language}) async {
    await _assertSimulated();

    await FakeUi.presentTutorial((_) => const TutorialScreen());

    return null;
  }

  @override
  Future<CertificatesInfo?> getCertificates({
    required EIDCertificateIndex type,
    String? language,
  }) async {
    await _assertSimulated();

    final outcome = await FakeUi.presentOutcome(
      (_) => const CertificatesScreen(),
    );

    return switch (outcome) {
      // There is exactly one hardcoded identity, so the requested [type] is
      // not honoured: the QES certificate is always what comes back.
      FakeProceed() => const CertificatesInfo(
        qscd: true,
        cardType: 'eID (SIMULATOR)',
        certificates: [
          Certificate(
            slot: 'QES',
            supportedSchemes: [FakeSigner.supportedSignatureScheme],
            isQualified: true,
            certIndex: 1,
            certData: FakeIdentity.certificateBase64,
          ),
        ],
      ),
      FakeError(error: final error) =>
        throw PlatformException(
          code: error.code,
          message: _certificatesErrorMessage,
          details: error.label,
        ),
      FakeCancel() =>
        FakeHostPlatform.isAndroid
            ? null
            : throw PlatformException(
              code: FakeErrorCase.cancelledByUser.code,
              message: _certificatesErrorMessage,
              details: FakeErrorCase.cancelledByUser.label,
            ),
    };
  }

  @override
  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false,
    String? language,
  }) async {
    await _assertSimulated();

    if (signatureScheme != FakeSigner.supportedSignatureScheme) {
      throw PlatformException(
        code: FakeErrorCase.unsupportedSignatureScheme.code,
        message: _signErrorMessage,
        details: FakeErrorCase.unsupportedSignatureScheme.label,
      );
    }

    final Uint8List data;
    try {
      data = FakeSigner.decodeDataToSign(
        dataToSign,
        isBase64Encoded: isBase64Encoded,
      );
    } on FormatException {
      // Malformed base64 must reach a host the same way any other signing
      // failure does, not as a raw Dart exception that bypasses
      // Eidmsdk.decodeNativeError.
      throw PlatformException(
        code: FakeErrorCase.signingFailed.code,
        message: _signErrorMessage,
        details: FakeErrorCase.signingFailed.label,
      );
    }

    final outcome = await FakeUi.presentOutcome(
      (_) => SignScreen(
        dataPreview: dataToSign,
        certIndex: certIndex,
        signatureScheme: signatureScheme,
      ),
    );

    return switch (outcome) {
      FakeProceed() => FakeSigner.signBase64(data),
      FakeError(error: final error) =>
        throw PlatformException(
          code: error.code,
          message: _signErrorMessage,
          details: error.label,
        ),
      FakeCancel() =>
        FakeHostPlatform.isAndroid
            ? null
            : throw PlatformException(
              code: FakeErrorCase.cancelledByUser.code,
              message: _signErrorMessage,
              details: FakeErrorCase.cancelledByUser.label,
            ),
    };
  }
}
