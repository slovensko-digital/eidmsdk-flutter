# TODO

Known outstanding work. Items are grouped by why they are outstanding, not by
severity — read the security section first.

## Security

- [ ] **Revoke the leaked GitHub PAT.** Commit `643f088` contains a literal
      `ghp_…` token, later replaced by the `EIDMSDK_ACCESS_TOKEN` environment
      variable. It is still reachable in history, so it must be revoked whether or
      not history is ever rewritten.

## Deferred from simulator support

- [ ] **Implement fake signing.** `SimulatorEidmsdk.signData`
      (`lib/eidmsdk_simulator.dart`) currently throws instead of returning a
      signature. It should sign with a hardcoded keystore and private certificate
      so that signing flows can be exercised end to end without a card. Deliberately
      throws rather than returning a placeholder, so a fake signature can never be
      mistaken for a real one — keep that property.
- [ ] Once signing works, replace the placeholder `certData`
      (`FAKE-SIMULATOR-CERTIFICATE`) with the matching hardcoded certificate, so
      callers that genuinely parse X.509 can be exercised too.
- [ ] Consider having `SimulatorEidmsdk` reproduce the native SHA-256-then-base64
      pre-hashing of `dataToSign`, so the fake and real signing paths agree on what
      is actually signed.

## iOS bugs (pre-existing, all in `ios/Classes/EidmsdkPlugin.swift`)

- [ ] **`setLogLevel` crashes on `EIDLogLevel.none`.** Line 56 does
      `eIDLogLevel(rawValue: rawLogLevel + 1)!`, but the SDK enum is 0-based
      (`verbose = 0 … none = 5`). Every level is shifted by one, and `none` (5)
      yields `rawValue 6` → `nil` → force-unwrap crash.
- [ ] **`getCertificates` requests the wrong certificate.** Line 74 does
      `eIDCertificateIndex(rawValue: type + 1)` while Dart already sends unshifted
      indices for iOS, so `qes` → `ES`, `es` → `Encryption`, and `encryption` → `nil`,
      silently dropped by `compactMap` (leaving an empty `types` array). Fixing this
      belongs with the `EIDCertificateIndex` API cleanup below.
- [ ] **Failed argument casts hang the Dart future.** The `guard`-else branches at
      lines 52, 69, 91, 96, 101 and 106 `print` and `return` without ever calling
      `result(...)`, so the awaiting `Future` never completes. They should return a
      `FlutterError`.
- [ ] Line 62 has a trailing comma in
      `showTutorial(from:environment: .minvProd,)`, which only compiles on
      Swift 6.1+ / Xcode 16.4+. Harmless today, but it needlessly narrows the
      supported toolchain.
- [ ] Line 133 uses `UIApplication.shared.windows`, deprecated since iOS 15, with a
      double force-unwrap in `findViewController()`.
- [ ] `language` is accepted by the Dart API but ignored on iOS (Android honours it).

## Android bugs (pre-existing)

- [ ] **Concurrent calls silently drop futures.** Pending results are held in single
      nullable fields (`getCertificatesResult` at line 187, `signDataResult` at
      line 204 of `android/src/main/kotlin/sk/freevision/eidmsdk/EidmsdkPlugin.kt`),
      so a second call overwrites the first and its `Future` never completes.
- [ ] `showTutorial` returns `success(false)` immediately (line 180) instead of
      waiting for the tutorial to close, unlike iOS which completes after dismissal.
      The two platforms should agree.
- [ ] `getCertificates` throws an uncaught `IllegalArgumentException` when `types`
      does not hold exactly one element (line 184). It should return a
      `FlutterError`, which is also what the existing `TODO` at line 110 is about.
- [ ] `android/src/test/kotlin/sk/freevision/eidmsdk/EidmsdkPluginTest.kt` is stale:
      it invokes `MethodCall("getPlatformVersion", null)` (line 21), and `null`
      arguments now hit the `ERROR_PARSE_ARGUMENTS` branch.

## API cleanups

These are the pre-existing `TODO` comments in the code, collected here for visibility:

- [ ] `getCertificates` should take a single `EIDCertificateIndex` rather than a list,
      since Android supports only one — `lib/eidmsdk_platform_interface.dart:49`.
      Doing this is the natural point to also fix the iOS off-by-one above and remove
      the platform-dependent offset in `lib/eidmsdk_method_channel.dart:51`.
- [ ] `dataToSign` should be base64-encoded or a `Uint8List` rather than a `String` —
      `lib/eidmsdk_platform_interface.dart:59`.
- [ ] `getPlatformVersion` is implemented on Android only and unused by Dart. Either
      expose it or drop it.

## Tooling and housekeeping

- [ ] Android builds need a JDK below 25 — see the troubleshooting note in
      `README.md`. Either pin it for everyone (`flutter config --jdk-dir=…`) or
      upgrade Gradle/AGP to a version that supports Java 25.
- [ ] There is no CI. At minimum, building the example for the simulator and running
      `flutter test` would have caught the two tests that were broken before the
      simulator work.
- [ ] `example/ios/Runner.xcodeproj/project.pbxproj` sets
      `SUPPORTED_PLATFORMS = iphoneos;` on the Release and Profile configurations, so
      only Debug can target the Simulator. Remove it if simulator release/profile
      builds are wanted.
- [ ] `tools/build_eid_stub.sh` must be re-run whenever the vendor SDK is updated. A
      stale stub is caught at compile time (see the note in the script), but it is
      still a manual step worth automating.
