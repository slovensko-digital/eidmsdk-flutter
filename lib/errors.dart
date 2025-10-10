/// Base eID mSDK exception type.
class EidmsdkException implements Exception {
  final String message;
  final dynamic details;

  EidmsdkException(this.message, [this.details]);

  @override
  String toString() {
    return "$runtimeType: $message";
  }
}

class CertificateNotFoundException extends EidmsdkException {
  CertificateNotFoundException(super.message, [super.details]);
}
