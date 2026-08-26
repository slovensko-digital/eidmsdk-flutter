# eID mSDK for Flutter

Flutter plugin project for `eID-mSDK` [iOS](https://github.com/eIDmSDK/eID-mSDK-iOS)
and [Android](https://github.com/eIDmSDK/eID-mSDK-Android).

The original SDK handles communication via NFC between mobile device and Slovak electronic identity card especially for digital document signing purposes.
Docs for the original SDK: <https://github.com/eIDmSDK/eID-mSDK-Dokumentacia>


## Accessing the package

Binaries of the package are hosted on GitHub package registry. To access the package during build process environment variable `EIDMSDK_ACCESS_TOKEN` needs to be set to GitHub Personal Access Token that has permission to read package registry.


## Running on a simulator or emulator

The eID mSDK communicates with the ID card over NFC, so it cannot work on an iOS
Simulator or an Android emulator. On top of that, the iOS SDK ships as a
device-only `arm64` binary, which used to make the plugin impossible to *build*
for the Simulator at all.

Both are handled automatically, with no setup in the host app:

* `ios/Frameworks/eID.xcframework` pairs the real device slice with a stub
  simulator slice, so a single `pod install` serves device, simulator and archive
  builds. Regenerate it with `tools/build_eid_stub.sh` after updating the vendor
  SDK or changing `tools/eid-stub/eID.swift`.
* At run time the plugin detects a simulated host and substitutes
  `SimulatorEidmsdk`, a fake implementation shared by both platforms.

> [!WARNING]
> **The certificate `getCertificates` returns and the signature `signData`
> produces are genuine RSA cryptography — and prove nothing about who signed
> what.** `getCertificates` and `signData` are interactive on a simulator or
> emulator (see
> [Testing with the simulator fake](#testing-with-the-simulator-fake) below),
> and the signature verifies against the certificate. Both are backed by a
> throwaway keypair whose private key is committed to this repository, so in
> the sense that matters — nobody signed anything — they must never be
> trusted as evidence.

`Eidmsdk.isUsingFake()` reports whether the fake is active — the example app uses
it to show a banner. iOS detection is compile-time and therefore exact — the
plugin is built against a stub Simulator slice that never links the real SDK.
Android detection is a heuristic, tuned to avoid false positives that would run
the fake on real hardware; detection also fails closed generally, so if it
cannot be completed for any reason the real implementation is kept. To opt out
explicitly, assign the real implementation yourself before
the first call:

```dart
EidmsdkPlatform.instance = MethodChannelEidmsdk();
```

Because the fake replaces `MethodChannelEidmsdk` wholesale rather than sitting
behind it, it does not reproduce the Android-only certificate-type offset:
`getCertificates` always returns the same single certificate, regardless of the
requested `types`.


## Testing with the simulator fake

On a simulator or emulator, each call presents a screen so every branch is
reachable by hand. All screens are white with black buttons and carry a
`SIMULATOR — FAKE eID SDK` banner.

| Call | Screen | Choices |
|---|---|---|
| `showTutorial()` | Tutorial | Close |
| `getCertificates()` | Certificates — shows Jozko Mrkvicka, Bratislava | Return certificate · Return error · Cancel |
| `signData()` | Sign data — shows the data, `certIndex` and scheme | Sign · Return error · Cancel |
| — | Error picker, opened from "Return error" above | one of 10 real eID error codes |

"Return error" opens a picker of 10 real eID error codes
(`certificatesNotIssued`, `signingFailed`, `kepPinBlocked`, …). The chosen code
is reported using the iOS `eIDError` vocabulary on both platforms, so it maps
to the same exception a real device produces through `Eidmsdk`'s error mapping
— `certificatesNotIssued` becomes `CertificateNotFoundException`, everything
else `EidmsdkException`. This is exact for iOS; a real Android device reports
Java exception class names instead (e.g. `CertificateNotFoundException` as a
class name rather than an `eIDError` case), so a host that inspects
`PlatformException.code` directly, rather than catching the exception types
`Eidmsdk` maps to, will see iOS-shaped codes on an Android emulator.

`signData` only supports one signature scheme,
`1.2.840.113549.1.1.11` (sha256WithRSAEncryption). Any other value throws the
real `unsupportedSignatureScheme` error.

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
`autoRespond` is ignored in release builds, so a release app always presents
the labelled screen — this is what keeps the fake from producing a silent,
unmarked signature if it were ever left set outside a test.

`SimulatorEidmsdk` also refuses to run at all outside a simulator or emulator,
throwing `EidmsdkException`. This is a call-time guard, checked again every time
a method runs rather than only when the platform is selected, so it closes the
case where a host assigns `SimulatorEidmsdk` directly, bypassing auto-detection.
It is what stands between an Android false positive and a genuine signature
produced silently: before the interactive fake and real signing existed, a
false positive cost a placeholder and a throw; now it would cost a verifying
signature, which is why this guard exists.

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


## Development

Flutter is pinned with [FVM](https://fvm.app) (`.fvmrc`), so prefix commands with
`fvm`.

```sh
fvm flutter test                      # plugin unit tests
cd example && fvm flutter test        # example widget test

# End-to-end against a simulator or emulator. Also covers the native
# `isSimulator` implementations, which the unit tests mock out.
cd example && fvm flutter test integration_test -d <simulator-or-emulator-id>
```

Regenerate the iOS xcframework after updating the vendor SDK or changing
`tools/eid-stub/eID.swift`:

```sh
tools/build_eid_stub.sh
```

A stale stub does not fail silently: the plugin compiles against the *real*
framework for device builds, so a vendor API change breaks the device build, and a
newly used SDK symbol breaks the simulator build. Both are compile-time failures.

Outstanding work is tracked in [TODO.md](TODO.md).

### Troubleshooting

**Android: `Error resolving plugin [id: 'dev.flutter.flutter-plugin-loader'] > 25.0.2`**

The trailing number is a *JDK* version, not a plugin version. Flutter defaults to
Android Studio's bundled JDK, and Gradle 8.14.4 does not support Java 25. Note that
setting `JAVA_HOME` does **not** help, because Flutter prefers Android Studio's JDK
over it — use Flutter's own setting instead:

```sh
fvm flutter config --jdk-dir="$(/usr/libexec/java_home -v 21)"
```

Verify with `fvm flutter doctor -v | grep "Java version"`. Unset it again with
`fvm flutter config --jdk-dir=`.

