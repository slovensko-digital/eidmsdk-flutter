import 'dart:convert' show base64Encode, utf8;

import 'package:flutter/foundation.dart';

import 'eidmsdk_platform_interface.dart';
import 'errors.dart';
import 'src/simulator/fake_ui.dart';
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
  /// Stand-in for the round trip through the SDK's own UI, so that callers'
  /// loading states are actually exercised instead of resolving instantly.
  static const _latency = Duration(milliseconds: 400);

  /// Obviously-not-a-certificate placeholder. It is valid base64 so that callers
  /// which merely decode it still work, but anything that genuinely parses X.509
  /// will fail loudly rather than quietly trust fake material.
  static final String _fakeCertData = base64Encode(
    utf8.encode('FAKE-SIMULATOR-CERTIFICATE'),
  );

  static Certificate _certificate(EIDCertificateIndex type) => Certificate(
    slot: switch (type) {
      EIDCertificateIndex.qes => 'QES',
      EIDCertificateIndex.es => 'ES',
      EIDCertificateIndex.encryption => 'Encryption',
    },
    supportedSchemes: const ['1.2.840.113549.1.1.11'],
    isQualified: type == EIDCertificateIndex.qes,
    certIndex: type.index + 1,
    certData: _fakeCertData,
  );

  @override
  Future<bool> setLogLevel({required EIDLogLevel logLevel}) async => true;

  @override
  Future showTutorial({String? language}) async {
    await FakeUi.presentTutorial((_) => const TutorialScreen());

    return null;
  }

  @override
  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
    String? language,
  }) async {
    await Future.delayed(_latency);

    if (types.length > 1) {
      // Android's native implementation requires exactly one type. Warn rather
      // than throw: a simulator should not be where that constraint is first met.
      debugPrint(
        'eidmsdk: getCertificates() was called with ${types.length} '
        'types. Android supports only one, so this would fail on a device.',
      );
    }

    return CertificatesInfo(
      qscd: true,
      cardType: 'eID (SIMULATOR)',
      certificates: types.map(_certificate).toList(),
    );
  }

  @override
  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false,
    String? language,
  }) async {
    await Future.delayed(_latency);

    // Signing with a hardcoded keystore and private certificate is not wired up
    // yet; it will be implemented here. Until then this throws rather than
    // returning a placeholder, so a fake signature can never be mistaken for a
    // real one.
    throw EidmsdkException(
      'signData is not implemented on the simulator/emulator '
      '- a fake keystore and certificate are not wired up yet.',
    );
  }
}
