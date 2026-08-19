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
