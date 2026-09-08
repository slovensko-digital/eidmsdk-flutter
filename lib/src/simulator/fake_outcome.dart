import 'fake_errors.dart';

/// What the user chose on a fake screen.
///
/// Sealed so that `SimulatorEidmsdk` dispatches with an exhaustive `switch`:
/// adding a case later becomes a compile error rather than a silent
/// fallthrough.
sealed class FakeOutcome {
  const FakeOutcome();
}

/// Continue with the happy path: return the certificate, or sign the data.
final class FakeProceed extends FakeOutcome {
  const FakeProceed();
}

/// Fail with a specific real error code.
final class FakeError extends FakeOutcome {
  const FakeError(this.error);

  final FakeErrorCase error;
}

/// The user backed out. Handled platform-faithfully by the caller.
final class FakeCancel extends FakeOutcome {
  const FakeCancel();
}
