/// Real eID error codes the simulator can raise on demand.
///
/// The codes are exactly those the native SDKs report, so the fake's errors
/// travel through the same `Eidmsdk.decodeNativeError` mapping as errors from a
/// real card. The labels are what the error-picker screen displays.
enum FakeErrorCase {
  certificatesNotIssued('certificatesNotIssued', 'Certificates not issued'),
  cancelledByUser('cancelledByUser', 'Cancelled by user'),
  certificateReadFailed('certificateReadFailed', 'Certificate read failed'),
  signingFailed('signingFailed', 'Signing failed'),
  unsupportedSignatureScheme(
      'unsupportedSignatureScheme', 'Unsupported signature scheme'),
  kepPinInvalid('kepPinInvalid', 'KEP PIN invalid'),
  kepPinBlocked('kepPinBlocked', 'KEP PIN blocked'),
  tagConnectionLost('tagConnectionLost', 'Card connection lost'),
  sessionTimeout('sessionTimeout', 'Session timeout'),
  nfcNotSupported('nfcNotSupported', 'NFC not supported');

  const FakeErrorCase(this.code, this.label);

  /// The code the native side would put in `FlutterError`/`PlatformException`.
  final String code;

  /// Human-readable text for the picker screen.
  final String label;
}
