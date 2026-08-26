# Simulator Fake UI and Signing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the simulator implementation interactive — fake screens for `showTutorial`, `getCertificates` and `signData`, every outcome reachable on demand, and a real RSA signature that verifies against the certificate the fake returns.

**Architecture:** A private `lib/src/simulator/` subsystem. `SimulatorEidmsdk` stays orchestration-only; a single `FakeUi` helper locates the host app's root `Navigator` by walking `WidgetsBinding.instance.rootElement` and pushes full-screen Material routes; signing is pure Dart via `pointycastle`. Errors are thrown as real `PlatformException`s so the existing `Eidmsdk.decodeNativeError` maps them exactly as it maps errors from a real card.

**Tech Stack:** Dart 3 sealed classes, Flutter Material, `pointycastle` ^4.0.0, `flutter_test` widget tests, OpenSSL 3.x for one-time identity generation.

**Spec:** `docs/superpowers/specs/2026-08-26-simulator-fake-ui-design.md`

## Global Constraints

- Flutter `>=3.29.3`, Dart SDK `>=3.7.2 <4.0.0`. Run all tooling through `fvm` (e.g. `fvm flutter test`).
- Only new dependency permitted: `pointycastle: ^4.0.0`. Do **not** add `basic_utils`, `crypto`, or `asn1lib`.
- **No Swift or Kotlin changes.** The native plugins keep only the `isSimulator` method they already have.
- Signature scheme supported: `1.2.840.113549.1.1.11` (sha256WithRSAEncryption). Anything else throws code `unsupportedSignatureScheme`.
- Certificate subject, exactly: `C=SK`, `L=Bratislava`, `CN=Jozko Mrkvicka`. Certificate validity `20200101000000Z`–`20400101000000Z`.
- Error messages, copied verbatim from the native implementations: `getCertificates` failures use `"Chyba pri načítaní podpisového certifikátu."`; `signData` failures use `"Chyba pri podpisovaní."`.
- Screen styling: `Scaffold` with white background, black filled buttons with white labels, and a permanent `SIMULATOR — FAKE eID SDK` label on every screen.
- Cancellation is platform-faithful: Android returns `null`; iOS throws `PlatformException(code: 'cancelledByUser')`.
- Everything under `lib/src/` is private. Only `lib/eidmsdk.dart` adds public exports.
- **`RSASigner.generateSignature()` hashes its input internally.** Always pass the raw message bytes. Pre-hashing then signing would double-hash and produce signatures that verify against nothing.

---

## File Structure

| File | Responsibility |
|---|---|
| `tools/generate_fake_identity.sh` | One-shot OpenSSL generation of the keypair + certificate; writes `fake_identity.dart` |
| `lib/src/simulator/fake_identity.dart` | Generated constants: RSA components and certificate DER |
| `lib/src/simulator/fake_signer.dart` | Decode `dataToSign`; RSA PKCS#1 v1.5 / SHA-256 signing |
| `lib/src/simulator/fake_errors.dart` | Catalogue of real eID error codes offered by the picker |
| `lib/src/simulator/fake_outcome.dart` | Sealed `FakeProceed \| FakeError \| FakeCancel` |
| `lib/src/simulator/fake_platform.dart` | Host-platform seam, overridable in tests |
| `lib/src/simulator/fake_ui.dart` | Root-`Navigator` discovery, `navigatorKey` fallback, `autoRespond` |
| `lib/src/simulator/screens/tutorial_screen.dart` | Tutorial screen |
| `lib/src/simulator/screens/certificates_screen.dart` | Certificates screen |
| `lib/src/simulator/screens/error_picker_screen.dart` | Error case picker, shared by two screens |
| `lib/src/simulator/screens/sign_screen.dart` | Signing screen |
| `lib/eidmsdk_simulator.dart` | Orchestration: screen → outcome → result or exception |
| `lib/eidmsdk.dart` | Adds `Eidmsdk.navigatorKey`, exports the new public types |

---

### Task 1: Fake identity

Generates the keypair and certificate once, and commits both the generator and its output. No new dependency yet — this task uses only `dart:convert` and `BigInt`.

**Files:**
- Create: `tools/generate_fake_identity.sh`
- Create: `lib/src/simulator/fake_identity.dart` (written by the script)
- Test: `test/simulator/fake_identity_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces: `class FakeIdentity` with `static final BigInt modulus, privateExponent, prime1, prime2, publicExponent`; `static const String certificateBase64`; `static Uint8List get certificateDer`; `static const String subjectCommonName = 'Jozko Mrkvicka'`; `static const String subjectLocality = 'Bratislava'`; `static const String subjectCountry = 'SK'`.

- [ ] **Step 1: Write the failing test**

Create `test/simulator/fake_identity_test.dart`:

```dart
import 'dart:convert';

import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeIdentity', () {
    test('is a 2048-bit RSA key', () {
      expect(FakeIdentity.modulus.bitLength, 2048);
      expect(FakeIdentity.publicExponent, BigInt.from(65537));
    });

    test('primes are consistent with the modulus', () {
      expect(FakeIdentity.prime1 * FakeIdentity.prime2, FakeIdentity.modulus);
    });

    test('certificate is decodable DER', () {
      expect(FakeIdentity.certificateDer.length, greaterThan(500));
      // DER SEQUENCE tag.
      expect(FakeIdentity.certificateDer.first, 0x30);
      expect(base64Encode(FakeIdentity.certificateDer),
          FakeIdentity.certificateBase64);
    });

    test('certificate and private key are a matched pair', () {
      // The modulus appears verbatim inside the certificate's
      // SubjectPublicKeyInfo, so this binds key to certificate without
      // needing an ASN.1 parser.
      final n = FakeIdentity.modulus;
      final nBytes = <int>[];
      var v = n;
      final byte = BigInt.from(256);
      while (v > BigInt.zero) {
        nBytes.insert(0, (v % byte).toInt());
        v = v ~/ byte;
      }
      expect(
        _indexOfSublist(FakeIdentity.certificateDer, nBytes),
        greaterThanOrEqualTo(0),
      );
    });
  });
}

int _indexOfSublist(List<int> haystack, List<int> needle) {
  for (var i = 0; i + needle.length <= haystack.length; i++) {
    var match = true;
    for (var j = 0; j < needle.length; j++) {
      if (haystack[i + j] != needle[j]) {
        match = false;
        break;
      }
    }
    if (match) return i;
  }
  return -1;
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/simulator/fake_identity_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package 'eidmsdk' ... fake_identity.dart` (the file does not exist yet).

- [ ] **Step 3: Write the generator script**

Create `tools/generate_fake_identity.sh` and `chmod +x` it:

```bash
#!/usr/bin/env bash
#
# Generates the fake signing identity used by SimulatorEidmsdk and writes it to
# lib/src/simulator/fake_identity.dart.
#
# This is a THROWAWAY, PUBLISHED keypair. It exists so that a developer without
# a card can produce signatures that actually verify. It is self-signed, trusted
# by nobody, and its private key is committed to this repository on purpose.
#
# Re-run only if the identity must change; the output is committed, so a normal
# checkout never needs to run this.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$REPO/lib/src/simulator/fake_identity.dart"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# A wide, fixed validity window: a certificate that expires would start failing
# tests years from now, and the failure would be hard to attribute.
openssl req -x509 -newkey rsa:2048 \
  -keyout "$TMP/key.pem" -out "$TMP/cert.pem" \
  -nodes -sha256 \
  -subj "/C=SK/L=Bratislava/CN=Jozko Mrkvicka" \
  -addext "keyUsage=critical,digitalSignature,nonRepudiation" \
  -not_before 20200101000000Z -not_after 20400101000000Z 2>/dev/null

openssl x509 -in "$TMP/cert.pem" -outform DER -out "$TMP/cert.der"

OUT="$OUT" python3 - "$TMP" <<'PY'
import base64, os, pathlib, re, subprocess, sys

tmp = pathlib.Path(sys.argv[1])
text = subprocess.run(
    ['openssl', 'rsa', '-in', str(tmp / 'key.pem'), '-text', '-noout'],
    capture_output=True, text=True, check=True).stdout


def component(label):
    match = re.search(rf'^{label}:\n((?:\s+[0-9a-f:]+\n)+)', text, re.M)
    if not match:
        raise SystemExit(f'could not parse {label} from openssl output')
    return re.sub(r'[^0-9a-f]', '', match.group(1))


def wrap(hex_digits):
    chunks = [hex_digits[i:i + 64] for i in range(0, len(hex_digits), 64)]
    return "\n      '".join(f"{c}'" for c in chunks)


der = (tmp / 'cert.der').read_bytes()
cert_b64 = base64.b64encode(der).decode()
cert_lines = "\n      '".join(
    f"{cert_b64[i:i + 64]}'" for i in range(0, len(cert_b64), 64))

pathlib.Path(os.environ['OUT']).write_text(f'''// GENERATED FILE - DO NOT EDIT BY HAND.
//
// Regenerate with: tools/generate_fake_identity.sh
//
// This is a THROWAWAY, PUBLISHED keypair used only by SimulatorEidmsdk on
// simulators and emulators. It is self-signed, trusted by nobody, and its
// private key is committed on purpose so that fake signatures actually verify.
// Never treat a signature made with it as evidence of anything.

import 'dart:convert';
import 'dart:typed_data';

/// The fake signing identity: a self-signed RSA-2048 certificate for
/// `CN=Jozko Mrkvicka, L=Bratislava, C=SK`, plus its private key components.
class FakeIdentity {{
  FakeIdentity._();

  static const String subjectCommonName = 'Jozko Mrkvicka';
  static const String subjectLocality = 'Bratislava';
  static const String subjectCountry = 'SK';

  static final BigInt modulus = BigInt.parse(
      '{wrap(component('modulus'))},
      radix: 16);

  static final BigInt privateExponent = BigInt.parse(
      '{wrap(component('privateExponent'))},
      radix: 16);

  static final BigInt prime1 = BigInt.parse(
      '{wrap(component('prime1'))},
      radix: 16);

  static final BigInt prime2 = BigInt.parse(
      '{wrap(component('prime2'))},
      radix: 16);

  static final BigInt publicExponent = BigInt.from(65537);

  /// The certificate, DER-encoded and base64-wrapped. Returned verbatim as
  /// `Certificate.certData`, exactly as the real SDK returns a certificate.
  static const String certificateBase64 =
      '{cert_lines};

  static Uint8List get certificateDer =>
      Uint8List.fromList(base64Decode(certificateBase64));
}}
''')
print('wrote', os.environ['OUT'])
PY
```

Note the string-concatenation trick: each `BigInt.parse` argument is a series of adjacent Dart string literals, which the compiler joins. That keeps generated lines under the formatter's line limit without embedding newlines in the value.

- [ ] **Step 4: Run the generator**

Run:
```bash
mkdir -p lib/src/simulator
chmod +x tools/generate_fake_identity.sh
tools/generate_fake_identity.sh
```
Expected: prints `wrote .../lib/src/simulator/fake_identity.dart`.

- [ ] **Step 5: Verify the generated file is well-formed**

Run: `fvm dart analyze lib/src/simulator/fake_identity.dart`
Expected: `No issues found!`

- [ ] **Step 6: Run the test to verify it passes**

Run: `fvm flutter test test/simulator/fake_identity_test.dart`
Expected: PASS, 4 tests.

- [ ] **Step 7: Commit**

```bash
git add tools/generate_fake_identity.sh lib/src/simulator/fake_identity.dart test/simulator/fake_identity_test.dart
git commit -m "Add generated fake signing identity for the simulator

A self-signed RSA-2048 certificate for CN=Jozko Mrkvicka, L=Bratislava,
committed together with the script that generates it so the identity is
reproducible and reviewable rather than an opaque blob.

The private key is committed deliberately: the fake needs to produce
signatures that actually verify, and a key that is trusted by nobody is not
a credential. The validity window is 2020-2040 so the certificate cannot
quietly expire and start failing tests years from now.

The test binds key to certificate by finding the modulus bytes inside the
certificate DER, which proves they are a matched pair without pulling in an
ASN.1 parser."
```

---

### Task 2: Fake signer

**Files:**
- Modify: `pubspec.yaml` (add `pointycastle: ^4.0.0`)
- Create: `lib/src/simulator/fake_signer.dart`
- Test: `test/simulator/fake_signer_test.dart`

**Interfaces:**
- Consumes: `FakeIdentity` from Task 1.
- Produces: `class FakeSigner` with `static const String supportedSignatureScheme = '1.2.840.113549.1.1.11'`; `static Uint8List decodeDataToSign(String dataToSign, {required bool isBase64Encoded})`; `static String signBase64(Uint8List data)`.

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, after `json_annotation`:

```yaml
  pointycastle: ^4.0.0
```

Run: `fvm flutter pub get`
Expected: resolves `pointycastle 4.0.0`. Its only transitive additions are `collection`, `convert` and `typed_data`, all already present in any Flutter app.

- [ ] **Step 2: Write the failing test**

Create `test/simulator/fake_signer_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:eidmsdk/src/simulator/fake_signer.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

/// Verifies with the public key only, the way a relying party would.
bool _verifies(Uint8List data, String signatureBase64) {
  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(
        false,
        PublicKeyParameter<RSAPublicKey>(
            RSAPublicKey(FakeIdentity.modulus, FakeIdentity.publicExponent)));

  return verifier.verifySignature(
    data,
    RSASignature(Uint8List.fromList(base64Decode(signatureBase64))),
  );
}

void main() {
  group('FakeSigner.decodeDataToSign', () {
    test('treats plain text as UTF-8 bytes', () {
      expect(
        FakeSigner.decodeDataToSign('hello world', isBase64Encoded: false),
        utf8.encode('hello world'),
      );
    });

    test('base64-decodes when told the input is encoded', () {
      final encoded = base64Encode(utf8.encode('hello world'));

      expect(
        FakeSigner.decodeDataToSign(encoded, isBase64Encoded: true),
        utf8.encode('hello world'),
      );
    });
  });

  group('FakeSigner.signBase64', () {
    test('produces a signature that verifies against the identity', () {
      final data = Uint8List.fromList(utf8.encode('hello world'));

      expect(_verifies(data, FakeSigner.signBase64(data)), isTrue);
    });

    test('produces a 2048-bit signature', () {
      final data = Uint8List.fromList(utf8.encode('hello world'));

      expect(base64Decode(FakeSigner.signBase64(data)).length, 256);
    });

    test('signature does not verify against different data', () {
      final signed = Uint8List.fromList(utf8.encode('hello world'));
      final tampered = Uint8List.fromList(utf8.encode('hello worlD'));

      expect(_verifies(tampered, FakeSigner.signBase64(signed)), isFalse);
    });

    test('is deterministic for the same input', () {
      final data = Uint8List.fromList(utf8.encode('hello world'));

      expect(FakeSigner.signBase64(data), FakeSigner.signBase64(data));
    });
  });
}
```

- [ ] **Step 3: Run test to verify it fails**

Run: `fvm flutter test test/simulator/fake_signer_test.dart`
Expected: FAIL — `Error: Couldn't resolve the package ... fake_signer.dart`.

- [ ] **Step 4: Write the implementation**

Create `lib/src/simulator/fake_signer.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/export.dart';

import 'fake_identity.dart';

/// Signs data with the throwaway [FakeIdentity] key.
///
/// Mirrors what the real plugin asks the SDK to do: an RSA PKCS#1 v1.5
/// signature over the SHA-256 digest of the data. The result verifies against
/// the certificate that `getCertificates` returns, so a host app can build a
/// real signature container from it — while the key itself is public and
/// trusted by nobody.
class FakeSigner {
  FakeSigner._();

  /// sha256WithRSAEncryption. The only scheme the fake identity supports.
  static const String supportedSignatureScheme = '1.2.840.113549.1.1.11';

  /// DER-encoded OID of SHA-256, as PointyCastle expects it for the PKCS#1
  /// DigestInfo wrapper.
  static const String _sha256DigestIdentifierHex = '0609608648016503040201';

  static Uint8List decodeDataToSign(
    String dataToSign, {
    required bool isBase64Encoded,
  }) =>
      Uint8List.fromList(
        isBase64Encoded ? base64Decode(dataToSign) : utf8.encode(dataToSign),
      );

  static String signBase64(Uint8List data) {
    final key = RSAPrivateKey(
      FakeIdentity.modulus,
      FakeIdentity.privateExponent,
      FakeIdentity.prime1,
      FakeIdentity.prime2,
    );

    final signer = RSASigner(SHA256Digest(), _sha256DigestIdentifierHex)
      ..init(true, PrivateKeyParameter<RSAPrivateKey>(key));

    // generateSignature digests its input itself and wraps the result in the
    // PKCS#1 DigestInfo structure. Pass the raw message: pre-hashing here
    // would hash twice and yield a signature that verifies against nothing.
    return base64Encode(signer.generateSignature(data).bytes);
  }
}
```

- [ ] **Step 5: Run test to verify it passes**

Run: `fvm flutter test test/simulator/fake_signer_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 6: Commit**

```bash
git add pubspec.yaml pubspec.lock lib/src/simulator/fake_signer.dart test/simulator/fake_signer_test.dart
git commit -m "Add real RSA signing for the simulator fake

Signs with the committed throwaway identity, producing an RSA PKCS#1 v1.5
signature over SHA-256 that verifies against the certificate the fake
returns. This is what lets a host app build a real signature container
without a card.

Note that RSASigner.generateSignature digests its own input and adds the
PKCS#1 DigestInfo wrapper, so it is handed the raw message. Pre-hashing
first would hash twice and produce signatures that verify against nothing --
the same trap that ruled out doing this natively, where iOS wants a digest
and Android wants a message.

Adds pointycastle, whose only transitive additions are collection, convert
and typed_data, all already present in any Flutter app."
```

---

### Task 3: Outcomes, error catalogue, platform seam

Three small files that later tasks all depend on, plus the proof that the fake's error codes map to the same exceptions a real device produces.

**Files:**
- Create: `lib/src/simulator/fake_outcome.dart`
- Create: `lib/src/simulator/fake_errors.dart`
- Create: `lib/src/simulator/fake_platform.dart`
- Test: `test/simulator/fake_errors_test.dart`

**Interfaces:**
- Consumes: nothing.
- Produces:
  - `sealed class FakeOutcome`; `final class FakeProceed extends FakeOutcome` (const ctor); `final class FakeError extends FakeOutcome` with `final FakeErrorCase error` (const ctor); `final class FakeCancel extends FakeOutcome` (const ctor).
  - `enum FakeErrorCase` with `final String code`, `final String label`, and values `certificatesNotIssued`, `cancelledByUser`, `certificateReadFailed`, `signingFailed`, `unsupportedSignatureScheme`, `kepPinInvalid`, `kepPinBlocked`, `tagConnectionLost`, `sessionTimeout`, `nfcNotSupported`.
  - `class FakeHostPlatform` with `static bool? debugIsAndroidOverride` and `static bool get isAndroid`.

- [ ] **Step 1: Write the failing test**

Create `test/simulator/fake_errors_test.dart`:

```dart
import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_platform.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FakeErrorCase', () {
    test('every case carries a non-empty code and label', () {
      for (final c in FakeErrorCase.values) {
        expect(c.code, isNotEmpty, reason: '${c.name} code');
        expect(c.label, isNotEmpty, reason: '${c.name} label');
      }
    });

    test('codes are unique', () {
      final codes = FakeErrorCase.values.map((c) => c.code).toList();

      expect(codes.toSet().length, codes.length);
    });

    test('certificatesNotIssued maps to CertificateNotFoundException', () {
      // Routed through the real mapping the plugin uses for device errors, so
      // the fake cannot drift from it.
      expect(
        () => Eidmsdk.decodeNativeError(
            PlatformException(code: FakeErrorCase.certificatesNotIssued.code)),
        throwsA(isA<CertificateNotFoundException>()),
      );
    });

    test('other cases map to EidmsdkException', () {
      for (final c in FakeErrorCase.values
          .where((c) => c != FakeErrorCase.certificatesNotIssued)) {
        expect(
          () => Eidmsdk.decodeNativeError(PlatformException(code: c.code)),
          throwsA(isA<EidmsdkException>()),
          reason: c.name,
        );
      }
    });
  });

  group('FakeOutcome', () {
    test('is exhaustively switchable', () {
      String describe(FakeOutcome outcome) => switch (outcome) {
            FakeProceed() => 'proceed',
            FakeError(error: final e) => 'error:${e.code}',
            FakeCancel() => 'cancel',
          };

      expect(describe(const FakeProceed()), 'proceed');
      expect(describe(const FakeCancel()), 'cancel');
      expect(
        describe(const FakeError(FakeErrorCase.signingFailed)),
        'error:signingFailed',
      );
    });
  });

  group('FakeHostPlatform', () {
    tearDown(() => FakeHostPlatform.debugIsAndroidOverride = null);

    test('honours the test override in both directions', () {
      FakeHostPlatform.debugIsAndroidOverride = true;
      expect(FakeHostPlatform.isAndroid, isTrue);

      FakeHostPlatform.debugIsAndroidOverride = false;
      expect(FakeHostPlatform.isAndroid, isFalse);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/simulator/fake_errors_test.dart`
Expected: FAIL — unresolved imports for `fake_errors.dart`, `fake_outcome.dart`, `fake_platform.dart`.

- [ ] **Step 3: Write the three implementation files**

Create `lib/src/simulator/fake_errors.dart`:

```dart
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
```

Create `lib/src/simulator/fake_outcome.dart`:

```dart
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
```

Create `lib/src/simulator/fake_platform.dart`:

```dart
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';

/// Which host platform the fake is pretending to be.
///
/// Exists so that platform-faithful behaviour — Android completing with `null`
/// on cancellation where iOS raises an error — can be tested on any machine.
class FakeHostPlatform {
  FakeHostPlatform._();

  /// Overrides the real platform check. Tests only.
  @visibleForTesting
  static bool? debugIsAndroidOverride;

  static bool get isAndroid => debugIsAndroidOverride ?? Platform.isAndroid;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/simulator/fake_errors_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/src/simulator/fake_errors.dart lib/src/simulator/fake_outcome.dart lib/src/simulator/fake_platform.dart test/simulator/fake_errors_test.dart
git commit -m "Add outcome type, error catalogue and platform seam for the fake

FakeOutcome is sealed so the orchestration switch is exhaustive and a future
case is a compile error rather than a silent fallthrough.

FakeErrorCase carries the genuine native error codes, which is what lets the
fake reuse Eidmsdk.decodeNativeError instead of duplicating the mapping. The
test asserts the mapping through that real function, so the fake's errors
cannot drift from the ones a device produces.

FakeHostPlatform exists purely so the platform-faithful cancellation
behaviour can be tested on either platform from any machine."
```

---

### Task 4: Presentation helper

The one place that touches unsupported API surface, and the choke point where `autoRespond` short-circuits.

**Files:**
- Create: `lib/src/simulator/fake_ui.dart`
- Test: `test/simulator/fake_ui_test.dart`

**Interfaces:**
- Consumes: `FakeOutcome`, `FakeCancel` from Task 3.
- Produces: `class FakeUi` with `static FakeOutcome? autoRespond`; `static GlobalKey<NavigatorState>? navigatorKey`; `static Future<FakeOutcome> presentOutcome(WidgetBuilder builder)`; `static Future<void> presentTutorial(WidgetBuilder builder)`; `@visibleForTesting static NavigatorState? findRootNavigator()`.

- [ ] **Step 1: Write the failing test**

Create `test/simulator/fake_ui_test.dart`:

```dart
import 'package:eidmsdk/errors.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() {
    FakeUi.autoRespond = null;
    FakeUi.navigatorKey = null;
  });

  testWidgets('finds the host app root navigator', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    expect(FakeUi.findRootNavigator(), isNotNull);
  });

  testWidgets('pushes a screen and returns the outcome it pops',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final result = FakeUi.presentOutcome(
      (context) => Scaffold(
        body: TextButton(
          onPressed: () =>
              Navigator.of(context).pop(const FakeError(FakeErrorCase.signingFailed)),
          child: const Text('fail'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('fail'));
    await tester.pumpAndSettle();

    expect(await result, isA<FakeError>());
  });

  testWidgets('treats a dismissed screen as cancellation', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));

    final result = FakeUi.presentOutcome(
      (context) => Scaffold(
        body: TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('back'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('back'));
    await tester.pumpAndSettle();

    expect(await result, isA<FakeCancel>());
  });

  testWidgets('autoRespond short-circuits without rendering', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    FakeUi.autoRespond = const FakeProceed();

    final result = await FakeUi.presentOutcome(
      (context) => const Scaffold(body: Text('should not appear')),
    );
    await tester.pump();

    expect(result, isA<FakeProceed>());
    expect(find.text('should not appear'), findsNothing);
  });

  testWidgets('autoRespond also short-circuits the tutorial', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: Scaffold()));
    FakeUi.autoRespond = const FakeProceed();

    await FakeUi.presentTutorial(
      (context) => const Scaffold(body: Text('should not appear')),
    );
    await tester.pump();

    expect(find.text('should not appear'), findsNothing);
  });

  testWidgets('throws a helpful error when there is no navigator to use',
      (tester) async {
    await tester.pumpWidget(const Directionality(
      textDirection: TextDirection.ltr,
      child: Text('no navigator here'),
    ));

    expect(
      () => FakeUi.presentOutcome((context) => const Placeholder()),
      throwsA(isA<EidmsdkException>().having(
        (e) => e.message,
        'message',
        contains('navigatorKey'),
      )),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/simulator/fake_ui_test.dart`
Expected: FAIL — unresolved import `fake_ui.dart`.

- [ ] **Step 3: Write the implementation**

Create `lib/src/simulator/fake_ui.dart`:

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../errors.dart';
import 'fake_outcome.dart';

/// Presents the fake screens without any cooperation from the host app.
///
/// The plugin has no `BuildContext` of its own, and requiring consuming apps to
/// attach a navigator key would break the promise that the simulator fake needs
/// no setup. So the host's root [Navigator] is located by walking the element
/// tree from [WidgetsBinding.rootElement].
///
/// That walk is the only unsupported API surface in this package. It is kept to
/// one function with one failure mode, so a future Flutter change is a
/// single-file repair, and [navigatorKey] lets a host unblock itself without
/// waiting for a plugin release.
class FakeUi {
  FakeUi._();

  /// When set, screens resolve to this outcome immediately and nothing renders.
  ///
  /// Exists so that host-app integration tests calling into the plugin do not
  /// hang waiting for a tap that never comes. Exposed publicly as
  /// `SimulatorEidmsdk.autoRespond`.
  static FakeOutcome? autoRespond;

  /// Optional escape hatch, exposed publicly as `Eidmsdk.navigatorKey`. Only
  /// consulted when walking the element tree finds nothing.
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Pushes [builder] and resolves to the outcome it pops.
  ///
  /// A screen dismissed without an explicit outcome — the system back button,
  /// for instance — counts as [FakeCancel].
  static Future<FakeOutcome> presentOutcome(WidgetBuilder builder) async {
    final shortCircuit = autoRespond;
    if (shortCircuit != null) {
      return shortCircuit;
    }

    final navigator = _requireNavigator();
    final outcome = await navigator.push<FakeOutcome>(
      MaterialPageRoute<FakeOutcome>(builder: builder),
    );

    return outcome ?? const FakeCancel();
  }

  /// Pushes [builder] for a screen with nothing to choose, such as the tutorial.
  static Future<void> presentTutorial(WidgetBuilder builder) async {
    if (autoRespond != null) {
      return;
    }

    await _requireNavigator().push<void>(
      MaterialPageRoute<void>(builder: builder),
    );
  }

  static NavigatorState _requireNavigator() {
    final navigator = findRootNavigator() ?? navigatorKey?.currentState;
    if (navigator == null) {
      throw EidmsdkException(
        'The eID simulator fake could not find a Navigator to present its '
        'screens on. Wrap your app in a MaterialApp, or assign '
        'Eidmsdk.navigatorKey to your app\'s navigatorKey.',
      );
    }

    return navigator;
  }

  /// Walks the element tree for the first [Navigator] in the host app.
  @visibleForTesting
  static NavigatorState? findRootNavigator() {
    final root = WidgetsBinding.instance.rootElement;
    if (root == null) {
      return null;
    }

    NavigatorState? found;

    void visit(Element element) {
      if (found != null) {
        return;
      }
      if (element is StatefulElement && element.state is NavigatorState) {
        found = element.state as NavigatorState;

        return;
      }
      element.visitChildElements(visit);
    }

    visit(root);

    return found;
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/simulator/fake_ui_test.dart`
Expected: PASS, 6 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/src/simulator/fake_ui.dart test/simulator/fake_ui_test.dart
git commit -m "Add presentation helper for the simulator fake screens

The plugin has no BuildContext of its own, and requiring consuming apps to
attach a navigator key would break the promise that the fake needs no setup.
So the host's root Navigator is located by walking the element tree from
WidgetsBinding.rootElement.

That walk is the only unsupported API surface in the package. It is confined
to one function with a single failure mode, and FakeUi.navigatorKey lets a
host unblock itself if a future Flutter release changes the tree, rather than
waiting for a plugin fix.

A screen dismissed without an explicit outcome counts as cancellation, so the
system back button behaves the way a user would expect. autoRespond
short-circuits before any of this, so host integration tests cannot hang."
```

---
### Task 5: Shared scaffold and tutorial screen

First screen, plus the styling every screen reuses.

**Files:**
- Create: `lib/src/simulator/screens/fake_scaffold.dart`
- Create: `lib/src/simulator/screens/tutorial_screen.dart`
- Modify: `lib/eidmsdk_simulator.dart` (rewrite `showTutorial`)
- Test: `test/simulator/screens/tutorial_screen_test.dart`

**Interfaces:**
- Consumes: `FakeUi.presentTutorial` from Task 4.
- Produces: `class FakeScaffold extends StatelessWidget` with `const FakeScaffold({required String title, required Widget body})`; `Widget fakeButton({required String label, required VoidCallback onPressed})` as a top-level function in the same file; `class TutorialScreen extends StatelessWidget` with `const TutorialScreen()`.

- [ ] **Step 1: Write the failing test**

Create `test/simulator/screens/tutorial_screen_test.dart`:

```dart
import 'package:eidmsdk/src/simulator/screens/tutorial_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows a title, the fake warning and a close button',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(home: TutorialScreen()));

    expect(find.text('Tutorial'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
  });

  testWidgets('close pops the screen', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => const TutorialScreen()),
          ),
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Tutorial'), findsOneWidget);

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Tutorial'), findsNothing);
    expect(find.text('open'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/simulator/screens/tutorial_screen_test.dart`
Expected: FAIL — unresolved import `tutorial_screen.dart`.

- [ ] **Step 3: Write the shared scaffold**

Create `lib/src/simulator/screens/fake_scaffold.dart`:

```dart
import 'package:flutter/material.dart';

/// Shared chrome for every fake screen: white background, a title, and a
/// permanent banner so a screenshot of one can never be mistaken for the real
/// SDK's UI.
class FakeScaffold extends StatelessWidget {
  const FakeScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: Text(title),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Text(
                'SIMULATOR — FAKE eID SDK',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: body,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A black filled button with a white label, per the agreed styling.
Widget fakeButton({required String label, required VoidCallback onPressed}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(),
        ),
        onPressed: onPressed,
        child: Text(label),
      ),
    ),
  );
}
```

- [ ] **Step 4: Write the tutorial screen**

Create `lib/src/simulator/screens/tutorial_screen.dart`:

```dart
import 'package:flutter/material.dart';

import 'fake_scaffold.dart';

/// Stands in for the real SDK's NFC tutorial, which cannot run on a simulator.
class TutorialScreen extends StatelessWidget {
  const TutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Tutorial',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'The real tutorial explains how to hold the card against the '
            'phone for NFC reading. There is no NFC on a simulator, so this '
            'screen only stands in for it.',
            style: TextStyle(color: Colors.black),
          ),
          const Spacer(),
          fakeButton(
            label: 'Close',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Wire `showTutorial`**

In `lib/eidmsdk_simulator.dart`, replace the existing `showTutorial` override with:

```dart
  @override
  Future showTutorial({String? language}) async {
    await FakeUi.presentTutorial((_) => const TutorialScreen());

    return null;
  }
```

Add these imports at the top of the file:

```dart
import 'src/simulator/fake_ui.dart';
import 'src/simulator/screens/tutorial_screen.dart';
```

Remove the now-obsolete `debugPrint` line and its comment about there being no `BuildContext`.

- [ ] **Step 6: Run tests to verify they pass**

Run: `fvm flutter test test/simulator/`
Expected: PASS. The tutorial tests are new; earlier tasks' tests still pass.

- [ ] **Step 7: Commit**

```bash
git add lib/src/simulator/screens/fake_scaffold.dart lib/src/simulator/screens/tutorial_screen.dart lib/eidmsdk_simulator.dart test/simulator/screens/tutorial_screen_test.dart
git commit -m "Add fake tutorial screen and shared screen chrome

FakeScaffold carries the styling every fake screen shares, including a
permanent SIMULATOR banner so a screenshot cannot be mistaken for the real
SDK's UI.

showTutorial now presents something instead of logging that it cannot. The
copy says plainly that there is no NFC on a simulator, rather than imitating
the real tutorial."
```

---

### Task 6: Error picker screen

Shared by the certificates and signing screens, so it lands before either.

**Files:**
- Create: `lib/src/simulator/screens/error_picker_screen.dart`
- Test: `test/simulator/screens/error_picker_screen_test.dart`

**Interfaces:**
- Consumes: `FakeErrorCase` from Task 3, `FakeScaffold`/`fakeButton` from Task 5.
- Produces: `class ErrorPickerScreen extends StatelessWidget` with `const ErrorPickerScreen()`. Pops a `FakeErrorCase`, or nothing if backed out.

- [ ] **Step 1: Write the failing test**

Create `test/simulator/screens/error_picker_screen_test.dart`:

```dart
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/screens/error_picker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('lists every error case', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ErrorPickerScreen()));

    for (final c in FakeErrorCase.values) {
      await tester.scrollUntilVisible(find.text(c.label), 100);
      expect(find.text(c.label), findsOneWidget, reason: c.name);
    }
  });

  testWidgets('pops the picked case', (tester) async {
    FakeErrorCase? picked;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            picked = await Navigator.of(context).push<FakeErrorCase>(
              MaterialPageRoute<FakeErrorCase>(
                  builder: (_) => const ErrorPickerScreen()),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text(FakeErrorCase.signingFailed.label));
    await tester.pumpAndSettle();

    expect(picked, FakeErrorCase.signingFailed);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/simulator/screens/error_picker_screen_test.dart`
Expected: FAIL — unresolved import `error_picker_screen.dart`.

- [ ] **Step 3: Write the implementation**

Create `lib/src/simulator/screens/error_picker_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../fake_errors.dart';
import 'fake_scaffold.dart';

/// Lets the developer choose which real eID error the fake should raise, so
/// every error branch in a host app is reachable on demand.
class ErrorPickerScreen extends StatelessWidget {
  const ErrorPickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Return error',
      body: ListView(
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Text(
              'The chosen code is reported exactly as the native SDK would '
              'report it, so it maps to the same exception a real device '
              'produces.',
              style: TextStyle(color: Colors.black),
            ),
          ),
          for (final errorCase in FakeErrorCase.values)
            fakeButton(
              label: errorCase.label,
              onPressed: () => Navigator.of(context).pop(errorCase),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `fvm flutter test test/simulator/screens/error_picker_screen_test.dart`
Expected: PASS, 2 tests.

- [ ] **Step 5: Commit**

```bash
git add lib/src/simulator/screens/error_picker_screen.dart test/simulator/screens/error_picker_screen_test.dart
git commit -m "Add error picker screen for the simulator fake

Makes every error branch in a host app reachable on demand rather than only
the happy path. Shared by the certificates and signing screens so the
outcome is chosen in exactly one place.

Each entry reports the genuine native error code, so what a host catches is
identical to what a real device would produce."
```

---

### Task 7: Certificates screen

**Files:**
- Create: `lib/src/simulator/screens/certificates_screen.dart`
- Modify: `lib/eidmsdk_simulator.dart` (rewrite `getCertificates`)
- Test: `test/simulator/screens/certificates_screen_test.dart`
- Test: `test/simulator/get_certificates_test.dart`

**Interfaces:**
- Consumes: `FakeIdentity` (Task 1), `FakeSigner.supportedSignatureScheme` (Task 2), `FakeOutcome`/`FakeErrorCase`/`FakeHostPlatform` (Task 3), `FakeUi.presentOutcome` (Task 4), `FakeScaffold`/`fakeButton` (Task 5), `ErrorPickerScreen` (Task 6).
- Produces: `class CertificatesScreen extends StatelessWidget` with `const CertificatesScreen()`, popping a `FakeOutcome`.

Note: the fake returns its single QES certificate regardless of the requested `types`, because there is exactly one hardcoded identity. This is a deliberate change from the previous behaviour of filtering by type.

- [ ] **Step 1: Write the failing screen test**

Create `test/simulator/screens/certificates_screen_test.dart`:

```dart
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/screens/certificates_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<FakeOutcome?> _open(WidgetTester tester) async {
  FakeOutcome? outcome;

  await tester.pumpWidget(MaterialApp(
    home: Builder(
      builder: (context) => TextButton(
        onPressed: () async {
          outcome = await Navigator.of(context).push<FakeOutcome>(
            MaterialPageRoute<FakeOutcome>(
                builder: (_) => const CertificatesScreen()),
          );
        },
        child: const Text('open'),
      ),
    ),
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();

  return outcome;
}

void main() {
  testWidgets('shows the fake identity', (tester) async {
    await _open(tester);

    expect(find.textContaining('Jozko Mrkvicka'), findsOneWidget);
    expect(find.textContaining('Bratislava'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
  });

  testWidgets('return certificate yields FakeProceed', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Return certificate'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('cancel yields FakeCancel', (tester) async {
    await _open(tester);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });

  testWidgets('return error opens the picker and propagates the choice',
      (tester) async {
    await _open(tester);

    await tester.tap(find.text('Return error'));
    await tester.pumpAndSettle();
    expect(find.text('Return error'), findsWidgets);

    await tester.tap(find.text(FakeErrorCase.certificatesNotIssued.label));
    await tester.pumpAndSettle();

    expect(find.text('open'), findsOneWidget);
  });
}
```

- [ ] **Step 2: Write the failing orchestration test**

Create `test/simulator/get_certificates_test.dart`:

```dart
import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_platform.dart';
import 'package:eidmsdk/src/simulator/fake_ui.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  setUp(() {
    EidmsdkPlatform.instance = platform;
    Eidmsdk.resetForTesting();
  });

  tearDown(() {
    FakeUi.autoRespond = null;
    FakeHostPlatform.debugIsAndroidOverride = null;
    Eidmsdk.resetForTesting();
  });

  test('proceeding returns the hardcoded certificate', () async {
    FakeUi.autoRespond = const FakeProceed();

    final result =
        await platform.getCertificates(types: [EIDCertificateIndex.qes]);

    expect(result, isNotNull);
    expect(result!.qscd, isTrue);
    expect(result.cardType, 'eID (SIMULATOR)');
    expect(result.certificates, hasLength(1));
    expect(result.certificates.single.slot, 'QES');
    expect(result.certificates.single.certIndex, 1);
    expect(result.certificates.single.certData,
        FakeIdentity.certificateBase64);
  });

  test('an error surfaces as the exception a real device would raise',
      () async {
    FakeUi.autoRespond =
        const FakeError(FakeErrorCase.certificatesNotIssued);

    // Through Eidmsdk, which applies the same mapping as for device errors.
    await expectLater(
      Eidmsdk().getCertificates(types: [EIDCertificateIndex.qes]),
      throwsA(isA<CertificateNotFoundException>()),
    );
  });

  test('cancel returns null on Android', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = true;

    expect(
      await Eidmsdk().getCertificates(types: [EIDCertificateIndex.qes]),
      isNull,
    );
  });

  test('cancel throws on iOS, matching the real SDK', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = false;

    await expectLater(
      Eidmsdk().getCertificates(types: [EIDCertificateIndex.qes]),
      throwsA(isA<EidmsdkException>()),
    );
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `fvm flutter test test/simulator/screens/certificates_screen_test.dart test/simulator/get_certificates_test.dart`
Expected: FAIL — unresolved import `certificates_screen.dart`.

- [ ] **Step 4: Write the screen**

Create `lib/src/simulator/screens/certificates_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../fake_errors.dart';
import '../fake_identity.dart';
import '../fake_outcome.dart';
import 'error_picker_screen.dart';
import 'fake_scaffold.dart';

/// Stands in for the real SDK's certificate-reading flow.
class CertificatesScreen extends StatelessWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Certificates',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${FakeIdentity.subjectCommonName}\n'
            '${FakeIdentity.subjectLocality}, ${FakeIdentity.subjectCountry}',
            style: const TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'One qualified signing certificate (QES). Self-signed and '
              'trusted by nobody.',
              style: TextStyle(color: Colors.black54),
            ),
          ),
          const Spacer(),
          fakeButton(
            label: 'Return certificate',
            onPressed: () =>
                Navigator.of(context).pop(const FakeProceed()),
          ),
          fakeButton(
            label: 'Return error',
            onPressed: () async {
              final picked = await Navigator.of(context).push<FakeErrorCase>(
                MaterialPageRoute<FakeErrorCase>(
                    builder: (_) => const ErrorPickerScreen()),
              );
              if (picked != null && context.mounted) {
                Navigator.of(context).pop(FakeError(picked));
              }
            },
          ),
          fakeButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(const FakeCancel()),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Wire `getCertificates`**

In `lib/eidmsdk_simulator.dart`, replace the `getCertificates` override with:

```dart
  @override
  Future<CertificatesInfo?> getCertificates({
    required List<EIDCertificateIndex> types,
    String? language,
  }) async {
    final outcome =
        await FakeUi.presentOutcome((_) => const CertificatesScreen());

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
      FakeError(error: final error) => throw PlatformException(
          code: error.code,
          message: _certificatesErrorMessage,
        ),
      FakeCancel() => FakeHostPlatform.isAndroid
          ? null
          : throw PlatformException(
              code: FakeErrorCase.cancelledByUser.code,
              message: _certificatesErrorMessage,
            ),
    };
  }
```

Add to the class body, above the overrides:

```dart
  /// Verbatim from the native implementations, so a host app sees the same
  /// message it would see from a real device.
  static const String _certificatesErrorMessage =
      'Chyba pri načítaní podpisového certifikátu.';
```

Add the imports:

```dart
import 'package:flutter/services.dart';

import 'src/simulator/fake_errors.dart';
import 'src/simulator/fake_identity.dart';
import 'src/simulator/fake_outcome.dart';
import 'src/simulator/fake_platform.dart';
import 'src/simulator/fake_signer.dart';
import 'src/simulator/screens/certificates_screen.dart';
```

Delete the now-unused `_latency`, `_fakeCertData` and `_certificate` members, and the `dart:convert` import if nothing else uses it.

- [ ] **Step 6: Run tests to verify they pass**

Run: `fvm flutter test test/simulator/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/src/simulator/screens/certificates_screen.dart lib/eidmsdk_simulator.dart test/simulator/screens/certificates_screen_test.dart test/simulator/get_certificates_test.dart
git commit -m "Return a real certificate from an interactive fake screen

getCertificates now presents a screen showing the fake identity and offering
success, a chosen error, or cancellation, and on success returns the genuine
self-signed certificate rather than the FAKE-SIMULATOR-CERTIFICATE
placeholder. Anything that parses certData now reads Jozko Mrkvicka.

The requested types are deliberately ignored: there is one hardcoded
identity, so the QES certificate is always what comes back.

Errors are thrown as PlatformException carrying the real native code, so the
existing decodeNativeError mapping turns them into exactly the exceptions a
device produces. Cancellation keeps the real SDK's asymmetry -- null on
Android, an error on iOS -- which is what makes the fake useful for catching
host bugs that would otherwise only appear on one platform."
```

---

### Task 8: Signing screen

**Files:**
- Create: `lib/src/simulator/screens/sign_screen.dart`
- Modify: `lib/eidmsdk_simulator.dart` (rewrite `signData`)
- Test: `test/simulator/screens/sign_screen_test.dart`
- Test: `test/simulator/sign_data_test.dart`

**Interfaces:**
- Consumes: everything from Tasks 1–6.
- Produces: `class SignScreen extends StatelessWidget` with `const SignScreen({required String dataPreview, required int certIndex, required String signatureScheme})`, popping a `FakeOutcome`.

- [ ] **Step 1: Write the failing screen test**

Create `test/simulator/screens/sign_screen_test.dart`:

```dart
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/screens/sign_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows what is being signed', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: SignScreen(
        dataPreview: 'hello world',
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.11',
      ),
    ));

    expect(find.textContaining('hello world'), findsOneWidget);
    expect(find.textContaining('1.2.840.113549.1.1.11'), findsOneWidget);
    expect(find.textContaining('FAKE eID SDK'), findsOneWidget);
    expect(find.text('Sign'), findsOneWidget);
    expect(find.text('Return error'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('sign pops FakeProceed', (tester) async {
    FakeOutcome? outcome;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (context) => TextButton(
          onPressed: () async {
            outcome = await Navigator.of(context).push<FakeOutcome>(
              MaterialPageRoute<FakeOutcome>(
                builder: (_) => const SignScreen(
                  dataPreview: 'hello world',
                  certIndex: 1,
                  signatureScheme: '1.2.840.113549.1.1.11',
                ),
              ),
            );
          },
          child: const Text('open'),
        ),
      ),
    ));

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign'));
    await tester.pumpAndSettle();

    expect(outcome, isA<FakeProceed>());
  });
}
```

- [ ] **Step 2: Write the failing orchestration test**

Create `test/simulator/sign_data_test.dart`:

```dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_errors.dart';
import 'package:eidmsdk/src/simulator/fake_identity.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:eidmsdk/src/simulator/fake_platform.dart';
import 'package:eidmsdk/src/simulator/fake_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pointycastle/export.dart';

const _scheme = '1.2.840.113549.1.1.11';

bool _verifies(String text, String signatureBase64) {
  final verifier = RSASigner(SHA256Digest(), '0609608648016503040201')
    ..init(
        false,
        PublicKeyParameter<RSAPublicKey>(
            RSAPublicKey(FakeIdentity.modulus, FakeIdentity.publicExponent)));

  return verifier.verifySignature(
    Uint8List.fromList(utf8.encode(text)),
    RSASignature(Uint8List.fromList(base64Decode(signatureBase64))),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  setUp(() {
    EidmsdkPlatform.instance = platform;
    Eidmsdk.resetForTesting();
  });

  tearDown(() {
    FakeUi.autoRespond = null;
    FakeHostPlatform.debugIsAndroidOverride = null;
    Eidmsdk.resetForTesting();
  });

  test('signing produces a signature that verifies against the certificate',
      () async {
    FakeUi.autoRespond = const FakeProceed();

    final signature = await platform.signData(
      certIndex: 1,
      signatureScheme: _scheme,
      dataToSign: 'hello world',
    );

    expect(signature, isNotNull);
    expect(_verifies('hello world', signature!), isTrue);
  });

  test('honours isBase64Encoded', () async {
    FakeUi.autoRespond = const FakeProceed();

    final signature = await platform.signData(
      certIndex: 1,
      signatureScheme: _scheme,
      dataToSign: base64Encode(utf8.encode('hello world')),
      isBase64Encoded: true,
    );

    expect(_verifies('hello world', signature!), isTrue);
  });

  test('rejects an unsupported signature scheme', () async {
    FakeUi.autoRespond = const FakeProceed();

    await expectLater(
      Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.5',
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>()),
    );
  });

  test('a chosen error surfaces as an exception', () async {
    FakeUi.autoRespond = const FakeError(FakeErrorCase.signingFailed);

    await expectLater(
      Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>()),
    );
  });

  test('cancel returns null on Android', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = true;

    expect(
      await Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      ),
      isNull,
    );
  });

  test('cancel throws on iOS, matching the real SDK', () async {
    FakeUi.autoRespond = const FakeCancel();
    FakeHostPlatform.debugIsAndroidOverride = false;

    await expectLater(
      Eidmsdk().signData(
        certIndex: 1,
        signatureScheme: _scheme,
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>()),
    );
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run: `fvm flutter test test/simulator/screens/sign_screen_test.dart test/simulator/sign_data_test.dart`
Expected: FAIL — unresolved import `sign_screen.dart`.

- [ ] **Step 4: Write the screen**

Create `lib/src/simulator/screens/sign_screen.dart`:

```dart
import 'package:flutter/material.dart';

import '../fake_errors.dart';
import '../fake_outcome.dart';
import 'error_picker_screen.dart';
import 'fake_scaffold.dart';

/// Stands in for the real SDK's PIN-and-sign flow. Signing here is real
/// cryptography with a throwaway key, so the result verifies — it just proves
/// nothing about who signed it.
class SignScreen extends StatelessWidget {
  const SignScreen({
    super.key,
    required this.dataPreview,
    required this.certIndex,
    required this.signatureScheme,
  });

  final String dataPreview;
  final int certIndex;
  final String signatureScheme;

  @override
  Widget build(BuildContext context) {
    return FakeScaffold(
      title: 'Sign data',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Data to sign',
              style: TextStyle(
                  color: Colors.black, fontWeight: FontWeight.bold)),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: const Color(0xFFF2F2F2),
              child: Text(
                dataPreview,
                maxLines: 6,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.black, fontFamily: 'monospace'),
              ),
            ),
          ),
          Text(
            'certIndex: $certIndex\nscheme: $signatureScheme',
            style: const TextStyle(color: Colors.black54),
          ),
          const Spacer(),
          fakeButton(
            label: 'Sign',
            onPressed: () => Navigator.of(context).pop(const FakeProceed()),
          ),
          fakeButton(
            label: 'Return error',
            onPressed: () async {
              final picked = await Navigator.of(context).push<FakeErrorCase>(
                MaterialPageRoute<FakeErrorCase>(
                    builder: (_) => const ErrorPickerScreen()),
              );
              if (picked != null && context.mounted) {
                Navigator.of(context).pop(FakeError(picked));
              }
            },
          ),
          fakeButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(context).pop(const FakeCancel()),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 5: Wire `signData`**

In `lib/eidmsdk_simulator.dart`, replace the `signData` override with:

```dart
  @override
  Future<String?> signData({
    required int certIndex,
    required String signatureScheme,
    required String dataToSign,
    bool isBase64Encoded = false,
    String? language,
  }) async {
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
      FakeError(error: final error) => throw PlatformException(
          code: error.code,
          message: _signErrorMessage,
        ),
      FakeCancel() => FakeHostPlatform.isAndroid
          ? null
          : throw PlatformException(
              code: FakeErrorCase.cancelledByUser.code,
              message: _signErrorMessage,
            ),
    };
  }
```

Add beside the other message constant:

```dart
  static const String _signErrorMessage = 'Chyba pri podpisovaní.';
```

Add the import:

```dart
import 'src/simulator/screens/sign_screen.dart';
```

- [ ] **Step 6: Run tests to verify they pass**

Run: `fvm flutter test test/simulator/`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/src/simulator/screens/sign_screen.dart lib/eidmsdk_simulator.dart test/simulator/screens/sign_screen_test.dart test/simulator/sign_data_test.dart
git commit -m "Sign for real from an interactive fake screen

signData now shows what is about to be signed, then produces a genuine RSA
signature that verifies against the certificate getCertificates returned --
so a host app can build a real signature container without a card. It no
longer throws 'not implemented'.

An unsupported signature scheme is rejected before the screen appears, with
the real unsupportedSignatureScheme code. Errors and cancellation behave as
they do for getCertificates, including the platform asymmetry."
```

---

### Task 9: Public surface and real-hardware guardrail

Exposes the two things consumers may touch, and makes the fake refuse to run where it must not.

**Files:**
- Modify: `lib/eidmsdk.dart` (add `navigatorKey`, export new types)
- Modify: `lib/eidmsdk_simulator.dart` (add `autoRespond` forwarder and the guard)
- Test: `test/simulator/guardrail_test.dart`

**Interfaces:**
- Consumes: `FakeUi` (Task 4), `MethodChannelEidmsdk.isSimulator` (already present).
- Produces: `static GlobalKey<NavigatorState>? Eidmsdk.navigatorKey` (getter and setter); `static FakeOutcome? SimulatorEidmsdk.autoRespond` (getter and setter); `@visibleForTesting static bool? SimulatorEidmsdk.debugAssumeSimulator`.

- [ ] **Step 1: Write the failing test**

Create `test/simulator/guardrail_test.dart`:

```dart
import 'package:eidmsdk/eidmsdk.dart';
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final platform = SimulatorEidmsdk();

  tearDown(() {
    SimulatorEidmsdk.autoRespond = null;
    SimulatorEidmsdk.debugAssumeSimulator = null;
  });

  test('refuses to run on real hardware', () async {
    SimulatorEidmsdk.debugAssumeSimulator = false;
    SimulatorEidmsdk.autoRespond = const FakeProceed();

    await expectLater(
      platform.signData(
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.11',
        dataToSign: 'hello world',
      ),
      throwsA(isA<EidmsdkException>().having(
        (e) => e.message,
        'message',
        contains('real hardware'),
      )),
    );
  });

  test('runs when the host is simulated', () async {
    SimulatorEidmsdk.debugAssumeSimulator = true;
    SimulatorEidmsdk.autoRespond = const FakeProceed();

    expect(
      await platform.signData(
        certIndex: 1,
        signatureScheme: '1.2.840.113549.1.1.11',
        dataToSign: 'hello world',
      ),
      isNotNull,
    );
  });

  test('autoRespond forwards to the presentation layer', () {
    SimulatorEidmsdk.autoRespond = const FakeCancel();

    expect(SimulatorEidmsdk.autoRespond, isA<FakeCancel>());
  });

  test('navigatorKey is settable and readable', () {
    final key = GlobalKey<NavigatorState>();
    Eidmsdk.navigatorKey = key;

    expect(Eidmsdk.navigatorKey, same(key));

    Eidmsdk.navigatorKey = null;
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `fvm flutter test test/simulator/guardrail_test.dart`
Expected: FAIL — `SimulatorEidmsdk.autoRespond` / `debugAssumeSimulator` / `Eidmsdk.navigatorKey` are not defined.

- [ ] **Step 3: Add the public surface and guard to `SimulatorEidmsdk`**

In `lib/eidmsdk_simulator.dart`, add to the class body:

```dart
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
```

Add `await _assertSimulated();` as the first statement of all four overrides: `setLogLevel`, `showTutorial`, `getCertificates` and `signData`.

Add the import:

```dart
import 'eidmsdk_method_channel.dart';
```

- [ ] **Step 4: Add `navigatorKey` and exports to `lib/eidmsdk.dart`**

Add to the `Eidmsdk` class body, beside the other statics:

```dart
  /// Optional escape hatch for the simulator fake's screens.
  ///
  /// The fake normally finds the host app's navigator by itself and needs no
  /// setup. Assign this to your app's `navigatorKey` only if it reports that it
  /// could not find one.
  static GlobalKey<NavigatorState>? get navigatorKey => FakeUi.navigatorKey;

  static set navigatorKey(GlobalKey<NavigatorState>? key) =>
      FakeUi.navigatorKey = key;
```

Add the imports and export:

```dart
import 'package:flutter/widgets.dart';

import 'src/simulator/fake_ui.dart';

export 'src/simulator/fake_errors.dart' show FakeErrorCase;
export 'src/simulator/fake_outcome.dart'
    show FakeOutcome, FakeProceed, FakeError, FakeCancel;
```

- [ ] **Step 5: Run the full suite**

Run: `fvm flutter test`
Expected: PASS for everything except the two known-stale tests handled in Task 10. If `test/eidmsdk_simulator_test.dart` fails on `signData throws`, that is expected — Task 10 fixes it.

- [ ] **Step 6: Commit**

```bash
git add lib/eidmsdk.dart lib/eidmsdk_simulator.dart test/simulator/guardrail_test.dart
git commit -m "Expose the fake's public surface and refuse to run on devices

Adds the two things a consuming app may touch: SimulatorEidmsdk.autoRespond,
so integration tests do not hang, and Eidmsdk.navigatorKey, the escape hatch
for the rare app where navigator discovery fails.

Also re-checks isSimulator when a method is called, not only when the
platform is selected. Auto-detection already prevents the fake reaching real
hardware, but a host can assign SimulatorEidmsdk directly; checking again at
call time means a fake signature cannot be produced on a device even then."
```

---

### Task 10: Update the tests this work invalidates

Two existing tests assert behaviour that is deliberately no longer true, and the example app needs its signing button to reflect that signing now works.

**Files:**
- Modify: `test/eidmsdk_simulator_test.dart`
- Modify: `example/integration_test/plugin_integration_test.dart`
- Modify: `example/lib/main.dart`

**Interfaces:**
- Consumes: `SimulatorEidmsdk.autoRespond` (Task 9), `FakeProceed` (Task 3).
- Produces: nothing new.

- [ ] **Step 1: Update the stale unit test**

In `test/eidmsdk_simulator_test.dart`:

- Delete the test `'signData throws rather than returning a fake signature'` — signing now succeeds, and `test/simulator/sign_data_test.dart` covers the new behaviour thoroughly.
- Delete the tests `'getCertificates honours the requested types'` and `'certData is decodable but obviously not a real certificate'` — the fake now returns one real certificate regardless of the requested types, which `test/simulator/get_certificates_test.dart` covers.
- The remaining tests call the fake without any UI, so add to `setUp`:

```dart
  setUp(() {
    SimulatorEidmsdk.autoRespond = const FakeProceed();
    SimulatorEidmsdk.debugAssumeSimulator = true;
  });

  tearDown(() {
    SimulatorEidmsdk.autoRespond = null;
    SimulatorEidmsdk.debugAssumeSimulator = null;
  });
```

and add these imports:

```dart
import 'package:eidmsdk/src/simulator/fake_outcome.dart';
```

- [ ] **Step 2: Run it**

Run: `fvm flutter test test/eidmsdk_simulator_test.dart`
Expected: PASS.

- [ ] **Step 3: Update the integration test**

In `example/integration_test/plugin_integration_test.dart`, replace the `signData` test with:

```dart
  testWidgets('signData returns a real signature', (WidgetTester tester) async {
    SimulatorEidmsdk.autoRespond = const FakeProceed();
    addTearDown(() => SimulatorEidmsdk.autoRespond = null);

    final signature = await plugin.signData(
      certIndex: 1,
      signatureScheme: '1.2.840.113549.1.1.11',
      dataToSign: 'hello world',
    );

    // 2048-bit RSA signature, base64-encoded.
    expect(signature, isNotNull);
    expect(base64Decode(signature!).length, 256);
  });
```

and replace the `getCertificates` test body's expectations with:

```dart
    SimulatorEidmsdk.autoRespond = const FakeProceed();
    addTearDown(() => SimulatorEidmsdk.autoRespond = null);

    final result =
        await plugin.getCertificates(types: [EIDCertificateIndex.qes]);

    expect(result, isNotNull);
    expect(result!.cardType, contains('SIMULATOR'));
    expect(result.certificates.single.slot, 'QES');
```

Add at the top:

```dart
import 'dart:convert';
```

- [ ] **Step 4: Run the integration test on a simulator**

Run:
```bash
cd example && fvm flutter test integration_test -d <simulator-id>
```
Expected: PASS, 3 tests. Get an id from `fvm flutter devices`.

- [ ] **Step 5: Update the example app**

In `example/lib/main.dart`, change the `signData` button label so it no longer implies failure, and leave the existing `_run` error handling in place — it now surfaces picked errors:

```dart
                ElevatedButton(
                  child: const Text('signData("hello world") — opens fake UI'),
                  onPressed: () => _run(
                    context,
                    () => _eidmsdkPlugin.signData(
                      certIndex: 1,
                      signatureScheme: "1.2.840.113549.1.1.11",
                      dataToSign: "hello world",
                    ),
                  ),
                ),
```

Update the banner text in `_FakeSdkBanner` to reflect that signing works:

```dart
            'Simulator detected: using the FAKE eID SDK.\n'
            'Certificates and signatures are real crypto from a public, '
            'worthless key — never trust them.',
```

- [ ] **Step 6: Verify the example widget test still passes**

The widget test matches `signData(` as a prefix, so the label change is safe.

Run: `cd example && fvm flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add test/eidmsdk_simulator_test.dart example/integration_test/plugin_integration_test.dart example/lib/main.dart
git commit -m "Update the tests and example the fake UI invalidates

Three assertions were deliberately made false by this work: that signData
throws, that certData is not a real certificate, and that getCertificates
filters by the requested types. Their replacements live in the focused
test/simulator/ suites, so they are deleted here rather than duplicated.

The integration test now sets autoRespond, which is exactly the pattern a
host app needs so its own tests do not hang on the fake's UI -- worth having
the example demonstrate.

The example's banner no longer says signing is unimplemented. It now warns
that the signatures are real crypto from a public, worthless key, which is a
more useful thing to tell a developer."
```

---

### Task 11: Documentation

**Files:**
- Modify: `README.md`
- Modify: `CHANGELOG.md`
- Modify: `TODO.md`
- Modify: `pubspec.yaml` (version bump)

**Interfaces:**
- Consumes: nothing.
- Produces: nothing.

- [ ] **Step 1: Add the Testing section to `README.md`**

Insert after the existing "Running on a simulator or emulator" section:

```markdown
## Testing with the simulator fake

On a simulator or emulator, each call presents a screen so every branch is
reachable by hand. All screens are white with black buttons and carry a
`SIMULATOR — FAKE eID SDK` banner.

| Call | Screen | Choices |
|---|---|---|
| `showTutorial()` | Tutorial | Close |
| `getCertificates()` | Certificates — shows Jozko Mrkvicka, Bratislava | Return certificate · Return error · Cancel |
| `signData()` | Sign — shows the data, `certIndex` and scheme | Sign · Return error · Cancel |

"Return error" opens a picker of real eID error codes
(`certificatesNotIssued`, `signingFailed`, `kepPinBlocked`, …). The chosen code
is reported exactly as the native SDK reports it, so it maps to the same
exception a real device produces — `certificatesNotIssued` becomes
`CertificateNotFoundException`, everything else `EidmsdkException`.

**Cancellation is platform-faithful**, matching the real SDK's asymmetry: on an
Android emulator the call completes with `null`; on an iOS Simulator it throws
`EidmsdkException`. An app that only handles one of those will fail on the other
platform, which is precisely what this is here to catch.

> [!WARNING]
> Signatures produced here are **real cryptography from a throwaway keypair
> whose private key is committed to this repository**. They verify against the
> certificate `getCertificates` returns, which is what makes them useful for
> exercising a signing pipeline — and they prove absolutely nothing about who
> signed what. Never accept one as evidence of anything.

### Keeping your own tests from hanging

The screens block until someone taps. Any automated test that calls into the
plugin must say in advance what should happen:

```dart
import 'package:eidmsdk/eidmsdk.dart';

setUp(() => SimulatorEidmsdk.autoRespond = const FakeProceed());
tearDown(() => SimulatorEidmsdk.autoRespond = null);
```

Use `FakeError(FakeErrorCase.signingFailed)` or `FakeCancel()` to drive the
other branches. Leave it unset to exercise the screens with a `WidgetTester`.

### If the fake cannot find your navigator

It locates your app's root `Navigator` by itself and needs no setup. If it ever
reports that it could not find one, hand it yours:

```dart
final navigatorKey = GlobalKey<NavigatorState>();

void main() {
  Eidmsdk.navigatorKey = navigatorKey;
  runApp(MaterialApp(navigatorKey: navigatorKey, home: const HomePage()));
}
```
```

- [ ] **Step 2: Bump the version**

In `pubspec.yaml`: `version: 1.2.0`. In `ios/eidmsdk.podspec`: `s.version = '1.2.0'`.

- [ ] **Step 3: Add the changelog entry**

At the top of `CHANGELOG.md`:

```markdown
# 1.2.0

* Simulator fake is now interactive: `showTutorial`, `getCertificates` and
  `signData` each present a screen, with success, a chosen error, or
  cancellation reachable on demand.
* `signData` now returns a **real** RSA signature that verifies against the
  certificate `getCertificates` returns, signed with a committed throwaway key.
  It no longer throws. The signatures prove nothing and must never be trusted.
* `getCertificates` returns a genuine self-signed certificate for
  `CN=Jozko Mrkvicka, L=Bratislava`, replacing the placeholder. It now returns
  one QES certificate regardless of the requested types.
* Cancellation is platform-faithful: `null` on Android, an exception on iOS.
* Added `SimulatorEidmsdk.autoRespond` so automated tests do not hang, and
  `Eidmsdk.navigatorKey` as a fallback if navigator discovery fails.
* `SimulatorEidmsdk` now refuses to run on real hardware.
* New dependency: `pointycastle`.

```

- [ ] **Step 4: Prune the completed `TODO.md` items**

Delete the whole "Deferred from simulator support" section — all three items are
now done: fake signing is implemented, the placeholder `certData` is replaced
with a real certificate, and the signing path hashes the data the way the native
side does.

- [ ] **Step 5: Verify everything**

Run:
```bash
fvm dart analyze lib test example/lib example/test example/integration_test
fvm flutter test
cd example && fvm flutter test
```
Expected: no analyzer issues; all tests pass.

- [ ] **Step 6: Commit**

```bash
git add README.md CHANGELOG.md TODO.md pubspec.yaml ios/eidmsdk.podspec
git commit -m "Document the simulator fake UI and bump to 1.2.0

The README's new Testing section covers the three things a developer using
this needs and cannot guess: that cancellation deliberately differs between
Android and iOS to mirror the real SDK, that autoRespond is required or their
own tests will hang on a blocking screen, and that the signatures are real
cryptography from a committed key and must never be trusted.

Also removes the three TODO items this work completes."
```

---

## Verification

After all tasks:

```bash
fvm flutter test                                   # plugin unit + widget tests
cd example && fvm flutter test                     # example widget test
cd example && fvm flutter test integration_test -d <simulator-id>
cd example && fvm flutter test integration_test -d <emulator-id>
cd example && fvm flutter build ios --simulator --debug
cd example && fvm flutter build ios --release --no-codesign
```

Then run the example on a simulator and walk each screen by hand: tutorial
closes; certificates returns Jozko Mrkvicka, and the error picker produces a
`CertificateNotFoundException` for `certificatesNotIssued`; signing returns a
344-character base64 signature; cancel returns `null` on Android and throws on
iOS.

Note that Android builds need a JDK below 25 on this machine — see the
troubleshooting note in `README.md`.
