# Simulator fake UI and signing — design

**Date:** 2026-08-26
**Status:** approved, ready for implementation planning
**Depends on:** the simulator support already on `feature/sdk-for-simulator`
(`eID.xcframework` + `SimulatorEidmsdk` auto-detection)

## Problem

`SimulatorEidmsdk` currently returns a canned certificate and throws from
`signData`. That is enough to make the app run on a simulator, but not enough to
exercise the flows that matter: there is no way to walk through a signing
journey, no way to drive the error and cancellation branches a host app must
handle, and no signature a host app can actually process.

This design adds interactive fake UI and real signing to the simulator
implementation, so that a developer without a card — and without a physical
device — can exercise every branch of the eID flows, and so a host app such as
Autogram can build a real signature container from the result.

## Goals

- Interactive fake screens for `showTutorial`, `getCertificates` and `signData`.
- Every outcome reachable on demand: success, a chosen error, cancellation.
- A genuine RSA signature that verifies against the certificate the fake returns.
- No setup in consuming apps.
- No hangs in automated tests.
- Dart unit tests and widget tests for the new UI.

## Non-goals

- Fidelity to the real SDK's visual design. These screens are deliberately
  plain, and deliberately marked as fake.
- Qualified-certificate semantics (`qcStatements` and friends). Add only if a
  host app turns out to check them.
- Any change to real-device behaviour. Nothing in this design executes on real
  hardware.

## Decisions

Each of these was chosen deliberately; the rejected alternative is recorded
because the reasoning is not obvious from the result.

| Decision | Chosen | Rejected, and why |
|---|---|---|
| Audience | Any consuming app, zero setup | Example-app-only would leave Autogram with no signing UI on a simulator; one-line setup breaks the zero-setup promise the auto-detection already makes, and an app that forgets the line gets a fake that silently cannot render. |
| Presentation | Discover the host's root `Navigator`; optional `Eidmsdk.navigatorKey` fallback | Discovery alone leaves consumers stranded if a Flutter upgrade changes the element tree. An `OverlayEntry` avoids the host route stack but loses back-button handling and is awkward to drive from widget tests. |
| Fidelity | Matched keypair; signature verifies against the returned certificate | A throwaway certificate breaks anything that parses it or checks the signer's public key — which is precisely what a document-signing app does. |
| Outcomes | Platform-faithful, plus an error picker | Uniform behaviour hides the real SDK's cancel asymmetry, so an app that mishandles iOS cancellation would look correct on a simulator and fail on a device. |
| Crypto location | Dart (`pointycastle`) | Native Swift + Kotlin avoids the dependency and would even compile out of iOS device builds, but the two platforms disagree on whether their signing API takes a digest or a message; getting that wrong yields signatures that silently verify against nothing. One implementation cannot drift from itself. |
| Test bypass | `SimulatorEidmsdk.autoRespond` | Auto-detecting the test environment is implicit and surprising when someone actually wants to test the screens. |

### Accepted costs

- Every consuming app gains `pointycastle` and its transitive dependencies,
  including production builds where the fake never runs.
- The fake's code and private key ship inside production binaries. The key is
  self-signed and worthless as a credential, but the code being present means the
  only thing preventing a forged signature on real hardware is a Dart-side check.
  Mitigated below, not eliminated.

## Architecture

```
lib/
  eidmsdk_simulator.dart        SimulatorEidmsdk - orchestration only, no UI code
  src/simulator/
    fake_ui.dart                root-Navigator discovery, push helper, key fallback
    fake_outcome.dart           sealed FakeProceed | FakeError | FakeCancel
    fake_errors.dart            catalogue of real eID error codes
    fake_identity.dart          certificate (base64 DER) + private key components
    fake_signer.dart            RSA PKCS#1 v1.5 over SHA-256, via pointycastle
    screens/
      tutorial_screen.dart
      certificates_screen.dart
      error_picker_screen.dart
      sign_screen.dart
tools/
  generate_fake_identity.sh     one-shot OpenSSL generation of the identity above
```

`lib/src/` is a new directory in a package whose `lib/` is currently flat. That
is deliberate: `src/` is the Dart convention for private implementation, only
`eidmsdk.dart` exports public API, and a UI subsystem should not sit beside the
platform interface.

No Swift or Kotlin changes. The native plugins keep only the `isSimulator`
method they already have.

### Presentation

`fake_ui.dart` is the only place that touches unsupported API surface. It walks
`WidgetsBinding.instance.rootElement` with `visitChildElements` to find the
host's root `Navigator`, pushes a `MaterialPageRoute<T>`, and awaits its result.
Verified available in Flutter 3.29.3, the version this package pins.

Resolution order:

1. the discovered root `Navigator`;
2. `Eidmsdk.navigatorKey`, if the host attached one;
3. otherwise throw an `EidmsdkException` naming the fix.

Keeping this in one ~15-line function with a single failure mode means a future
Flutter change is a one-file repair, and the `navigatorKey` escape hatch lets a
host unblock itself without waiting for a plugin release.

### Screens

Four full-screen `MaterialPageRoute`s. White `Scaffold`, black filled buttons
with white labels, and a permanent "SIMULATOR — FAKE eID SDK" label so a
screenshot cannot be mistaken for the real SDK.

| Screen | Content | Actions |
|---|---|---|
| Tutorial | Title, placeholder body | Close |
| Certificates | The fake identity (Jozko Mrkvicka, Bratislava) | Return certificate · Return error · Cancel |
| Error picker | Real eID error cases | one per case, Back |
| Sign | Data preview, `certIndex`, `signatureScheme` | Sign · Return error · Cancel |

"Return error" on the certificates and sign screens pushes the error picker, so
the outcome is chosen in exactly one place.

`FakeError` carries only the error **code**. The accompanying message is supplied
by the calling method, matching what each native side sends today —
`"Chyba pri načítaní podpisového certifikátu."` for `getCertificates` and
`"Chyba pri podpisovaní."` for `signData` — so the same picked case yields the
message a host would actually see from that call.

`fake_outcome.dart` defines a Dart 3 sealed hierarchy — `FakeProceed`,
`FakeError(case)`, `FakeCancel` — so `SimulatorEidmsdk` dispatches with an
exhaustive `switch` and a future case becomes a compile error rather than a
silent fallthrough.

### Error and cancellation semantics

The fake throws a real `PlatformException` carrying the genuine native code and
message (`certificatesNotIssued`, `signingFailed`, `kepPinBlocked`, …).
`Eidmsdk.getCertificates` and `Eidmsdk.signData` already wrap their calls in
`try / on PlatformException => decodeNativeError`, so the fake's errors flow
through **the same mapping as real ones**. A host catching
`CertificateNotFoundException` sees it identically whether the error came from a
card or from the picker. There is no second mapping table, so the two cannot
drift.

Cancellation reuses that mechanism and preserves the real SDK's asymmetry:

- **Android emulator** — completes with `null`.
- **iOS Simulator** — throws `PlatformException(code: "cancelledByUser")`, which
  the existing wrapper converts to `EidmsdkException`.

### Identity and signing

`tools/generate_fake_identity.sh` runs OpenSSL once to produce an RSA-2048
self-signed X.509: subject `CN=Jozko Mrkvicka, L=Bratislava, C=SK`, `keyUsage =
digitalSignature, nonRepudiation`, validity 2020–2040. The wide window is
intentional: an expiring certificate would start failing tests years later, and
the failure would be hard to attribute. The script is committed so the identity
is reproducible and reviewable rather than an opaque blob.

`fake_identity.dart` stores the certificate as base64 DER — opaque, only ever
returned as `certData` — and the private key as BigInt components (`n`, `d`,
`p`, `q`), so `RSAPrivateKey` is constructed directly and the package needs no
ASN.1 parsing code and no `basic_utils` dependency.

`fake_signer.dart` mirrors the real plugin's semantics: decode `dataToSign`
honouring `isBase64Encoded`, SHA-256 it, sign with
`RSASigner(SHA256Digest(), ...)` (which emits the correct PKCS#1 v1.5
DigestInfo), and base64-encode the result.

`getCertificates` returns exactly one certificate:

```
slot: "QES", certIndex: 1, isQualified: true,
supportedSchemes: ["1.2.840.113549.1.1.11"],
certData: <base64 DER>, cardType: "eID (SIMULATOR)", QSCD: true
```

A `signatureScheme` outside `supportedSchemes` throws the real
`unsupportedSignatureScheme` code.

### Guardrail

`SimulatorEidmsdk` re-checks `isSimulator` when a method is **called**, not only
when the platform is selected. On real hardware it throws an `EidmsdkException`
naming the misconfiguration, rather than returning a signature or failing
silently. This closes
the case where a host assigns `SimulatorEidmsdk` directly, bypassing
auto-detection. It is a Dart-side check and therefore weaker than compiling the
code out of the binary; that is the accepted cost of a single implementation.

## Testing

### Dart unit tests

- The signature from `signData` verifies against the public key inside the
  `certData` that `getCertificates` returned. This is the test that gives
  "matched pair" meaning.
- `isBase64Encoded` true and false both hash the intended bytes.
- Each error case surfaces the exception a host would see from a real device,
  asserted through `Eidmsdk`'s real wrapper rather than a reimplementation.
- Cancellation is checked on both platform branches, driven by overriding the
  reported platform so both run on any machine.
- An unsupported `signatureScheme` throws `unsupportedSignatureScheme`.
- `autoRespond` short-circuits without rendering, for every screen.
  `showTutorial` has no outcome to choose, so any non-null value simply makes it
  return immediately.

### Widget tests

One file per screen: it renders, the fake label is present, and each button
produces the expected `FakeOutcome`; plus "Return error" pushing the picker and
the picked case propagating. No method-channel mocking is required, because the
fake never calls the channel.

### Existing tests this invalidates

- `test/eidmsdk_simulator_test.dart` — "signData throws rather than returning a
  fake signature" stops being true. It becomes the verifies-against-certificate
  test.
- `example/integration_test/plugin_integration_test.dart` — "signData reports
  that it is not implemented" likewise. It becomes: set `autoRespond`, assert a
  real signature is returned.

## Documentation

- `README.md` gains a **Testing** section: the four screens and their buttons,
  the platform-faithful cancellation asymmetry, driving the screens from widget
  tests, using `autoRespond` from host-app integration tests, and the standing
  warning that these signatures are real cryptography from a published,
  worthless key and must never be trusted.
- `CHANGELOG.md` gains a `1.2.0` entry.
- `TODO.md`: remove the three now-completed items — implementing fake signing,
  replacing the placeholder `certData`, and reproducing the native SHA-256
  pre-hashing so the fake and real signing paths agree on what is signed.
