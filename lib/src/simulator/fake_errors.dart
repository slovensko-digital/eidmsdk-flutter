/// Real eID error codes the simulator can raise on demand.
///
/// These are the iOS `eIDError` vocabulary (`EidmsdkPlugin.swift` sends
/// `String(describing: error)`, i.e. the enum case name) and are used on both
/// platforms. They are exact for iOS. A real Android device does not report
/// this vocabulary: `EidmsdkPlugin.kt` sends `e.javaClass.simpleName`, a Java
/// exception class name such as `CertificateNotFoundException`, not an
/// `eIDError` case. So a host that inspects `PlatformException.code` directly
/// — rather than catching the mapped exception types via
/// `Eidmsdk.decodeNativeError` — will see iOS-shaped codes on an emulator that
/// a real Android device would never produce. Going through
/// `Eidmsdk.decodeNativeError`, as this catalogue's codes do, still lands on
/// the same exception types either way. The labels are what the error-picker
/// screen displays.
enum FakeErrorCase {
  certificatesNotIssued('certificatesNotIssued', 'Certificates not issued'),
  cancelledByUser('cancelledByUser', 'Cancelled by user'),
  certificateReadFailed('certificateReadFailed', 'Certificate read failed'),
  signingFailed('signingFailed', 'Signing failed'),
  unsupportedSignatureScheme(
    'unsupportedSignatureScheme',
    'Unsupported signature scheme',
  ),
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
