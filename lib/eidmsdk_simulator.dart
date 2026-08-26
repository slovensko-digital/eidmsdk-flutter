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
/// **This produces no real signatures and no real certificates.** Everything it
/// returns is canned and marked as such.
///
/// What it deliberately does *not* emulate, because it replaces
/// [MethodChannelEidmsdk] wholesale rather than sitting behind it:
///
///  * the Android-only `+1` offset applied to [EIDCertificateIndex] values,
///  * the native SHA-256-then-base64 pre-hashing of `dataToSign`,
///  * real [PlatformException] codes, so [CertificateNotFoundException] never
///    surfaces here,
///  * Android's "user cancelled" behaviour of completing with `null`,
///  * the tutorial UI.
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
  /// Auto-detection already prevents this, but a host can assign
  /// [SimulatorEidmsdk] directly. Checking again at call time means a fake
  /// signature cannot be produced on a device even then.
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
    required List<EIDCertificateIndex> types,
    String? language,
  }) async {
    await _assertSimulated();

    final outcome = await FakeUi.presentOutcome(
      (_) => const CertificatesScreen(),
    );

    return switch (outcome) {
      // There is exactly one hardcoded identity, so the requested types are
      // not honoured: the QES certificate is always what comes back.
      FakeProceed() => CertificatesInfo(
        qscd: true,
        cardType: 'eID (SIMULATOR)',
        certificates: [
          Certificate(
            slot: 'QES',
            supportedSchemes: const [FakeSigner.supportedSignatureScheme],
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
        ),
      FakeCancel() =>
        FakeHostPlatform.isAndroid
            ? null
            : throw PlatformException(
              code: FakeErrorCase.cancelledByUser.code,
              message: _certificatesErrorMessage,
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
      );
    }

    final data = FakeSigner.decodeDataToSign(
      dataToSign,
      isBase64Encoded: isBase64Encoded,
    );

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
        throw PlatformException(code: error.code, message: _signErrorMessage),
      FakeCancel() =>
        FakeHostPlatform.isAndroid
            ? null
            : throw PlatformException(
              code: FakeErrorCase.cancelledByUser.code,
              message: _signErrorMessage,
            ),
    };
  }
}
