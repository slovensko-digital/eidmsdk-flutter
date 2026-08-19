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
> **The fake produces no real signatures and no real certificates.**
> `getCertificates` returns a canned payload whose `certData` is the literal
> string `FAKE-SIMULATOR-CERTIFICATE`, and `signData` throws an
> `EidmsdkException` rather than returning a placeholder signature, so a fake
> signature can never be mistaken for a real one. Signing with a hardcoded
> keystore and certificate is not implemented yet.

`Eidmsdk.isUsingFake()` reports whether the fake is active — the example app uses
it to show a banner. Detection fails closed: if it cannot be completed for any
reason the real implementation is kept, so the fake can never stand in on real
hardware. To opt out explicitly, assign the real implementation yourself before
the first call:

```dart
EidmsdkPlatform.instance = MethodChannelEidmsdk();
```

Because the fake replaces `MethodChannelEidmsdk` wholesale rather than sitting
behind it, it does not reproduce the Android-only certificate-type offset, the
native SHA-256 pre-hashing of `dataToSign`, real `PlatformException` codes, or
Android's "user cancelled" `null` result.
