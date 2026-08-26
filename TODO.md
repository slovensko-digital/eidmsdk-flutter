# TODO

Known outstanding work, grouped by why it is outstanding rather than by severity
— read the security section first.

Items reference functions rather than line numbers on purpose: line numbers in
this file went stale repeatedly, and a symbol name survives edits.

## Security

- [ ] **Revoke the leaked GitHub PAT.** Commit `643f088` contains a literal
      `ghp_…` token, later replaced by the `EIDMSDK_ACCESS_TOKEN` environment
      variable. It is still reachable in history, so it needs revoking whether or
      not the history is ever rewritten. Nothing else here matters as much.

## Correctness — `ios/Classes/EidmsdkPlugin.swift`

- [ ] **Failed argument casts hang the Dart future.** Five `guard`-else branches
      — one in `setLogLevel`, four in `signData` — `print` and `return` without
      ever calling `result(...)`, so the awaiting `Future` never completes and
      the caller has no way to notice. They should return a `FlutterError`.
      The Android side of this exact defect is already fixed (it reports
      `ERROR_PARSE_ARGUMENTS` naming the argument), so iOS is now the outlier;
      `getCertificates` on iOS is likewise already fixed and shows the shape to
      copy.
- [ ] `findViewController()` uses `UIApplication.shared.windows`, deprecated
      since iOS 15, and force-unwraps twice. It will return the wrong window in
      a multi-scene app and crash if there is no visible window.

## Correctness — `android/.../EidmsdkPlugin.kt`

- [ ] **Concurrent calls silently drop futures.** Pending results live in single
      nullable fields (`getCertificatesResult`, `signDataResult`), so a second
      call overwrites the first and the earlier `Future` never completes. Two
      overlapping `signData` calls are enough to reproduce it.

## Platform behaviour that disagrees

- [ ] `showTutorial` completes immediately on Android — it calls
      `EIDHandler.startTutorial` and then `success(false)` without waiting —
      while iOS completes only after the tutorial is dismissed. Callers cannot
      treat the future as "the user has finished reading" on both platforms.
      Documented on `Eidmsdk.showTutorial`; the platforms should agree instead.
- [ ] `EIDLanguage` is honoured on Android and ignored on iOS, which always uses
      the device language. Documented, not fixed.

## API

- [ ] `dataToSign` should be base64 or a `Uint8List` rather than a `String`
      (`// TODO` in `lib/eidmsdk_platform_interface.dart`). Both natives hash it
      before it reaches the SDK, so passing text through a `String` is lossy for
      any binary payload.
- [ ] `Eidmsdk`'s methods each read `(await _platform())` inline
      (`// TODO` in `lib/eidmsdk.dart`). Worth resolving to a local for
      readability.

## Verification gaps

- [ ] **The fake's signature construction is unverified against real hardware.**
      `FakeSigner` produces `RSA_PKCS1v15(DigestInfo(SHA256(data)))`, while the
      natives hand the SDK `base64(SHA256(data))`. These agree only if the vendor
      SDK treats that input as an already-computed digest. That is the obviously
      intended contract and the assumption is documented in `FakeSigner`, but
      confirming it needs a physical card. If it is wrong, simulator signatures
      differ in construction from device ones and nothing would reveal it.
- [ ] There is no CI. Building the example for the simulator plus
      `flutter test` and `./gradlew :eidmsdk:testDebugUnitTest` would cover the
      three suites that exist; every regression found during the simulator work
      was something one of those runs would have caught.

## Housekeeping

- [ ] Android builds need a JDK below 25. Flutter prefers Android Studio's
      bundled JDK, which is 25, and Gradle 8.14.4 rejects it — the failure
      surfaces as a misleading `Error resolving plugin … > 25.0.2`. See the
      troubleshooting note in `README.md`. Either pin it for everyone
      (`flutter config --jdk-dir=…`) or move to a Gradle/AGP that supports 25.
- [ ] Six files are not `dart format`-stable and predate the recent work:
      `lib/eidmsdk_method_channel.dart`, `lib/eidmsdk_platform_interface.dart`,
      `lib/types.dart`, `lib/types.g.dart`,
      `test/eidmsdk_method_channel_test.dart`, `test/eidmsdk_test.dart`.
      They were left alone deliberately, to keep formatting churn out of
      unrelated diffs. Formatting them is a one-command commit of its own —
      note `types.g.dart` is generated, so check what `build_runner` emits first.
- [ ] `example/ios/Runner.xcodeproj/project.pbxproj` sets
      `SUPPORTED_PLATFORMS = iphoneos;` on the Release and Profile
      configurations, so only Debug can target the Simulator. Remove it if
      simulator release/profile builds are wanted.
- [ ] `tools/build_eid_stub.sh` must be re-run whenever the vendor iOS SDK is
      updated. A stale stub fails at compile time rather than silently, but it is
      still a manual step worth automating.
