# 2.0.0

**Breaking:** `getCertificates` now takes a single `type` instead of a
`types` list. Android only ever supported one, and the list gave callers a
shape the platform could not honor. Replace `types: [EIDCertificateIndex.qes]`
with `type: EIDCertificateIndex.qes`.

* Fix iOS requesting the wrong certificate. `eIDCertificateIndex` is 0-based, but
  the plugin added 1 to it, so asking for `qes` returned the `ES` certificate,
  `es` returned `Encryption`, and `encryption` was silently dropped. Nobody
  could read their QES certificate on iOS.
* Fix `setLogLevel` crashing on iOS. The same off-by-one made
  `EIDLogLevel.none` produce an out-of-range raw value, which was then
  force-unwrapped. Invalid levels now return an error instead of crashing.
* The certificate type is sent as the Dart enum's own index and mapped to each
  SDK's enum natively, so there is no longer a platform-dependent offset in
  Dart. `eidmsdk_method_channel.dart` no longer imports `dart:io`.
* Android returns an `ERROR_INVALID_CERTIFICATE_TYPE` error for an unknown
  certificate type rather than throwing `IndexOutOfBoundsException`.
* **Breaking:** `language` is now an `EIDLanguage` (`slovak` / `english`) instead
  of a free-form `String`. It crosses the wire as the `sk` / `en` code the native
  SDKs expect. Still honored on Android and ignored on iOS.
* Android reports a missing or wrongly-typed argument as `ERROR_PARSE_ARGUMENTS`,
  naming the argument, instead of throwing out of `onMethodCall` and leaving the
  Dart future to hang forever. `MethodCall.argument` casts without checking, so
  the wrong-type case needed a runtime check rather than a null check.
* Removed `getPlatformVersion`, which existed only on Android and was never
  called from Dart.
* iOS: dropped a trailing comma in the `showTutorial` call that required
  Swift 6.1+/Xcode 16.4+ to compile at all.

# 1.2.0

* Simulator fake is now interactive: `showTutorial`, `getCertificates` and
  `signData` each present a screen, with success, a chosen error, or
  cancellation reachable on demand.
* `signData` now returns a **real** RSA signature that verifies against the
  certificate `getCertificates` returns, signed with a committed throwaway key.
  It no longer throws. The signatures prove nothing and must never be trusted.
* `getCertificates` returns a genuine self-signed certificate for
  `CN=Jozko Mrkvicka, L=Bratislava, C=SK`, replacing the placeholder. It now
  returns one QES certificate regardless of the requested types.
* Cancellation is platform-faithful: `null` on Android, an exception on iOS.
* Added `SimulatorEidmsdk.autoRespond` so automated tests do not hang, and
  `Eidmsdk.navigatorKey` as a fallback if navigator discovery fails.
* `SimulatorEidmsdk` now refuses to run on real hardware.
* New dependency: `pointycastle`.

# 1.1.0

* Support running on the iOS Simulator and the Android emulator.
* iOS: ship the mSDK as `eID.xcframework`, pairing the real device slice with a
  stub simulator slice, so the plugin can be built for the Simulator at all.
  Regenerate with `tools/build_eid_stub.sh`.
* Add `SimulatorEidmsdk`, a fake implementation substituted automatically on a
  simulated host. It returns canned certificates and **no real signatures**;
  `signData` throws until hardcoded keystore signing is implemented.
* Add `Eidmsdk.isUsingFake()` and `Eidmsdk.ensureInitialized()`.
* `package:eidmsdk/eidmsdk.dart` now exports the enums, model and error types, so
  importing the platform-interface file directly is no longer necessary.

# 1.0.0

* Update native eID mSDK dependencies
* Update Flutter v3.29.3 / Dart v3.7.2
* Android: Update Gradle v8.14.4, AGP v8.13.2, Kotlin v2.2.21, Compile SDK: 36
* iOS: Update deployment target to iOS v14.0

# 0.9.1

* Rethrowing native Android and iOS exception as specific ones derived from `EidmsdkException`.

# 0.9.0

* Update native eID mSDK dependencies

# 0.0.1

* Initial release
