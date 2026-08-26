# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

Flutter is pinned by FVM (`.fvmrc`, 3.29.3) and **bare `flutter`/`dart` are not on
PATH** — every command needs the `fvm` prefix.

```sh
fvm flutter test                                   # plugin suite
fvm flutter test test/simulator/fake_signer_test.dart          # one file
fvm flutter test test/x_test.dart --plain-name "some test"     # one test
fvm dart analyze lib test example/lib example/test example/integration_test

cd example && fvm flutter test                     # example widget test
cd example/android && ./gradlew :eidmsdk:testDebugUnitTest     # Android unit tests

# Integration tests need a booted simulator/emulator; they exercise the native
# isSimulator path that the unit tests mock out.
cd example && fvm flutter test integration_test -d <device-id>

cd example && fvm flutter build ios --simulator --debug
cd example && fvm flutter build ios --release --no-codesign    # compiles against the REAL SDK
```

`lib/types.dart` is `json_serializable`; regenerate with
`fvm dart run build_runner build --delete-conflicting-outputs`.

**Android builds fail out of the box.** Flutter prefers Android Studio's bundled
JDK (25), which Gradle 8.14.4 rejects, and the error is misleading:
`Error resolving plugin [dev.flutter.flutter-plugin-loader] > 25.0.2` — that
number is a JDK version. `JAVA_HOME` does not help; use
`fvm flutter config --jdk-dir="$(/usr/libexec/java_home -v 21)"`. Calling
`./gradlew` directly works regardless, which is why the Android unit-test command
above bypasses the Flutter tool.

## Architecture

A plugin wrapping the Slovak eID mSDK, which reads an ID card over NFC.

Three layers: the `Eidmsdk` facade → the `EidmsdkPlatform` interface → one of two
implementations. `MethodChannelEidmsdk` talks to the native SDKs;
`SimulatorEidmsdk` is a fake. `Eidmsdk` picks between them once, on first call,
memoizing a `Future` (detection needs a native round trip but
`EidmsdkPlatform.instance` is synchronous). Detection fails closed — any error
keeps the real implementation, so the fake can never stand in on hardware.

### Why the simulator machinery exists

The vendor's iOS SDK ships as a **device-only arm64 binary**, so before this
existed the plugin could not even be *compiled* for the Simulator. Two pieces
solve that:

- `ios/Frameworks/eID.xcframework` pairs the real vendor device slice with a
  hand-written stub simulator slice, built from `tools/eid-stub/eID.swift` by
  `tools/build_eid_stub.sh`. **Re-run that script after any vendor SDK update.**
  The stub only needs to compile and link — it is never reached at runtime.
- `SimulatorEidmsdk` (`lib/eidmsdk_simulator.dart` + `lib/src/simulator/`)
  supplies the behavior, and covers the Android emulator too, which has no NFC
  either.

The fake presents real Flutter screens from a package that owns no
`BuildContext`, by walking `WidgetsBinding.instance.rootElement` for the host's
root `Navigator`. That is the **only unsupported-API surface in the package** and
is deliberately confined to one function in `lib/src/simulator/fake_ui.dart`, with
`Eidmsdk.navigatorKey` as an escape hatch.

Its certificate and signature are **real cryptography from a keypair committed on
purpose** (`tools/generate_fake_identity.sh`, needs OpenSSL 3.5+ for
`-not_before`). They verify, and they prove nothing — never treat a simulator
signature as evidence. `SimulatorEidmsdk` re-checks `isSimulator` at *call* time,
not just at selection, and refuses to run on hardware.

### Two design rules worth preserving

**Errors reuse the real mapping.** The fake throws genuine `PlatformException`s
carrying the native error codes, so they travel through the same
`Eidmsdk.decodeNativeError` as device errors. There is deliberately no second
mapping table for the fake to drift from. Note the codes are the *iOS* vocabulary
(`eIDError` case names); real Android devices report Throwable class names.

**The certificate type is mapped natively, not in Dart.** The wire value is
`EIDCertificateIndex.index`; iOS indexes its 0-based `eIDCertificateIndex`
directly, Android shifts past the extra leading `ALL` in `EIDCertificateType`.
Keeping that per-SDK, rather than as an offset computed in Dart, is what removed
a long-standing off-by-one. `test/eidmsdk_method_channel_test.dart` pins the wire
contract; a change there silently breaks one platform.

### Platform behavior that genuinely differs

These are real and documented on the methods — not bugs to "fix" by unifying:

- **Cancellation:** Android completes with `null`; iOS raises an error that
  surfaces as `EidmsdkException`. Code handling only one breaks on the other.
- **`showTutorial`:** resolves after dismissal on iOS, immediately on Android.
- **`EIDLanguage`:** honored on Android, ignored on iOS.
- **`setLogLevel`:** a logged no-op returning `false` on Android.

`setLogLevel` and `showTutorial` are not wrapped in `decodeNativeError`, so they
surface raw `PlatformException`s unlike the other two.

## Conventions

- Anything under `lib/src/` is private; only `lib/eidmsdk.dart` adds exports.
- **Comments, doc comments, Markdown and test descriptions use American English**
  — `behavior`, `honored`, `catalog`, `memoized`, `labeled`, `center`. Identifiers
  are exempt where the spelling is a wire value or a vendor API: `cancelledByUser`
  is the iOS `eIDError` case name and must keep its spelling, as must the
  `'Cancelled by user'` label that mirrors it.
- Tests that call into the plugin must set `SimulatorEidmsdk.autoRespond`, or the
  fake's blocking screens hang them. It is ignored in release builds, so a
  release can never suppress the on-screen fake banner.
- Six files are knowingly not `dart format`-stable and are left alone to keep
  churn out of unrelated diffs — see `TODO.md`. Do not reformat them incidentally;
  `lib/types.g.dart` among them is generated.
- `EIDMSDK_ACCESS_TOKEN` must be set to a GitHub PAT with package-read scope for
  the Android SDK to resolve. iOS needs nothing — its binary is committed.

`TODO.md` tracks known outstanding defects; `docs/superpowers/` holds the design
spec and implementation plan for the simulator work.
