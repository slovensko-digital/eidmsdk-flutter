# TODO

Known outstanding work. Items are grouped by why they are outstanding, not by
severity — read the security section first.

## Security

- [ ] **Revoke the leaked GitHub PAT.** Commit `643f088` contains a literal
      `ghp_…` token, later replaced by the `EIDMSDK_ACCESS_TOKEN` environment
      variable. It is still reachable in history, so it must be revoked whether or
      not history is ever rewritten.

## iOS bugs (pre-existing, all in `ios/Classes/EidmsdkPlugin.swift`)

- [ ] **Failed argument casts hang the Dart future.** The `guard`-else branches at
      lines 52, 69, 91, 96, 101 and 106 `print` and `return` without ever calling
      `result(...)`, so the awaiting `Future` never completes. They should return a
      `FlutterError`.
- [ ] Line 133 uses `UIApplication.shared.windows`, deprecated since iOS 15, with a
      double force-unwrap in `findViewController()`.
- [ ] `EIDLanguage` is accepted by the Dart API but ignored on iOS, which always uses
      the device language. Android honours it.

## Android bugs (pre-existing)

- [ ] **Concurrent calls silently drop futures.** Pending results are held in single
      nullable fields (`getCertificatesResult` at line 187, `signDataResult` at
      line 204 of `android/src/main/kotlin/sk/freevision/eidmsdk/EidmsdkPlugin.kt`),
      so a second call overwrites the first and its `Future` never completes.
- [ ] `showTutorial` returns `success(false)` immediately (line 180) instead of
      waiting for the tutorial to close, unlike iOS which completes after dismissal.
      The two platforms should agree.

## API cleanups

These are the pre-existing `TODO` comments in the code, collected here for visibility:

- [ ] `dataToSign` should be base64-encoded or a `Uint8List` rather than a `String` —
      `lib/eidmsdk_platform_interface.dart:59`.

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
