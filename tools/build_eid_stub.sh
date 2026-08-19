#!/usr/bin/env bash
#
# Builds ios/Frameworks/eID.xcframework from:
#   - the real, vendor-supplied device slice (arm64, iPhoneOS)
#   - a hand-written simulator stub slice built from tools/eid-stub/eID.swift
#
# The real eID mSDK ships a single device-only arm64 slice, so the plugin cannot
# be built for the iOS Simulator. Wrapping both slices in an .xcframework lets
# CocoaPods pick the right one per platform, so a single `pod install` serves
# device, simulator and archive builds.
#
# The device slice is never modified or duplicated -- it is the source of truth
# and is read straight out of the existing xcframework (or, on the very first
# run, out of the legacy ios/Frameworks/eID.framework location).
#
# Re-run this after updating the vendor SDK, or after changing the stub source.
#
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STUB_SRC="$REPO/tools/eid-stub/eID.swift"
XC="$REPO/ios/Frameworks/eID.xcframework"
LEGACY="$REPO/ios/Frameworks/eID.framework"

# Must match the vendor's own build flags, taken from the device slice's
# arm64-apple-ios.swiftinterface header:
#   -target arm64-apple-ios14.0 -enable-library-evolution -swift-version 5
DEPLOYMENT_TARGET="14.0"
SIM_ARCHS=(arm64 x86_64)

# Library evolution is REQUIRED, not optional: without it the emitted
# .swiftmodule is pinned to the exact compiler version, and any Xcode upgrade
# breaks `import eID` with "module compiled with Swift X cannot be imported by
# Swift Y". It also produces the .swiftinterface the resilient import path uses.
SWIFT_FLAGS=(-enable-library-evolution -swift-version 5 -O)

log() { printf '\033[1;34m==>\033[0m %s\n' "$*"; }

# --- locate the pristine device slice -----------------------------------------
if [[ -d "$XC/ios-arm64/eID.framework" ]]; then
  DEVICE_FW="$XC/ios-arm64/eID.framework"
elif [[ -d "$LEGACY" ]]; then
  DEVICE_FW="$LEGACY"
else
  echo "error: no device eID.framework found at either:" >&2
  echo "  $XC/ios-arm64/eID.framework" >&2
  echo "  $LEGACY" >&2
  exit 1
fi
log "device slice: ${DEVICE_FW#$REPO/}"

if [[ "$(lipo -info "$DEVICE_FW/eID" 2>&1)" != *arm64* ]]; then
  echo "error: $DEVICE_FW/eID is not an arm64 binary" >&2
  exit 1
fi

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# --- build the stub, one dylib per simulator arch ------------------------------
SDK="$(xcrun --sdk iphonesimulator --show-sdk-path)"
SIM_FW="$TMP/sim/eID.framework"
mkdir -p "$SIM_FW/Modules/eID.swiftmodule" "$SIM_FW/Headers"

for arch in "${SIM_ARCHS[@]}"; do
  log "compiling stub for $arch-apple-ios$DEPLOYMENT_TARGET-simulator"
  mkdir -p "$TMP/$arch"
  xcrun swiftc \
    -emit-library -emit-module \
    -module-name eID \
    -target "$arch-apple-ios$DEPLOYMENT_TARGET-simulator" \
    -sdk "$SDK" \
    "${SWIFT_FLAGS[@]}" \
    -emit-module-path           "$TMP/$arch/eID.swiftmodule" \
    -emit-module-interface-path "$TMP/$arch/$arch-apple-ios-simulator.swiftinterface" \
    -emit-objc-header-path      "$TMP/$arch/eID-Swift.h" \
    -Xclang-linker -isysroot -Xclang-linker "$SDK" \
    -Xlinker -install_name -Xlinker "@rpath/eID.framework/eID" \
    -o "$TMP/$arch/eID" \
    "$STUB_SRC"

  # Arch-prefixed filenames inside eID.swiftmodule/ are mandatory -- this is how
  # the compiler locates the right module for the arch being built.
  cp "$TMP/$arch/eID.swiftmodule" \
     "$SIM_FW/Modules/eID.swiftmodule/$arch-apple-ios-simulator.swiftmodule"
  cp "$TMP/$arch/$arch-apple-ios-simulator.swiftinterface" \
     "$SIM_FW/Modules/eID.swiftmodule/$arch-apple-ios-simulator.swiftinterface"
done

# --- assemble the simulator framework bundle ----------------------------------
log "assembling fat simulator binary (${SIM_ARCHS[*]})"
lipo -create -output "$SIM_FW/eID" $(printf "$TMP/%s/eID " "${SIM_ARCHS[@]}")

cp "$TMP/${SIM_ARCHS[0]}/eID-Swift.h" "$SIM_FW/Headers/eID-Swift.h"

# Mirror the device slice's modulemap verbatim.
cp "$DEVICE_FW/Modules/module.modulemap" "$SIM_FW/Modules/module.modulemap"

# Versions are kept identical to the device slice so the two stay recognisably
# the same SDK; only the platform differs. No resources: the stub renders no UI,
# so Assets.car / tutorial.json / storyboards / *.lproj are all omitted.
DEV_PLIST="$DEVICE_FW/Info.plist"
SHORT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$DEV_PLIST")"
BUNDLE_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleVersion' "$DEV_PLIST")"
BUNDLE_ID="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleIdentifier' "$DEV_PLIST")"

cat > "$SIM_FW/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>CFBundleDevelopmentRegion</key><string>en</string>
	<key>CFBundleExecutable</key><string>eID</string>
	<key>CFBundleIdentifier</key><string>$BUNDLE_ID</string>
	<key>CFBundleInfoDictionaryVersion</key><string>6.0</string>
	<key>CFBundleName</key><string>eID</string>
	<key>CFBundlePackageType</key><string>FMWK</string>
	<key>CFBundleShortVersionString</key><string>$SHORT_VERSION</string>
	<key>CFBundleVersion</key><string>$BUNDLE_VERSION</string>
	<key>CFBundleSupportedPlatforms</key><array><string>iPhoneSimulator</string></array>
	<key>DTPlatformName</key><string>iphonesimulator</string>
	<key>MinimumOSVersion</key><string>$DEPLOYMENT_TARGET</string>
	<key>UIDeviceFamily</key><array><integer>1</integer></array>
</dict>
</plist>
PLIST

# --- combine into the xcframework ---------------------------------------------
# -create-xcframework refuses to write over an existing directory, so build into
# the temp dir first and swap it in.
log "creating eID.xcframework"
# The bundle must keep the name eID.framework -- xcodebuild derives the expected
# executable name from it -- so isolate the copy in its own directory.
mkdir -p "$TMP/device"
cp -R "$DEVICE_FW" "$TMP/device/eID.framework"
xcodebuild -create-xcframework \
  -framework "$TMP/device/eID.framework" \
  -framework "$SIM_FW" \
  -output "$TMP/eID.xcframework" >/dev/null

# `xcodebuild -create-xcframework` strips binary .swiftmodule files whenever a
# .swiftinterface is present -- including from the vendor's own device slice.
# That is Apple's intended design, but the vendor shipped their interface with
# -no-verify-emitted-module-interface, i.e. it was never checked to actually
# compile, so dropping their prebuilt binary module would put the *device* build
# at risk. Restore both slices to exactly what we built / the vendor shipped,
# keeping only Apple's generated Info.plist and directory layout.
log "restoring pristine slice contents (create-xcframework strips .swiftmodule)"
for slice in "$TMP/eID.xcframework"/*/; do
  slice_name="$(basename "$slice")"
  case "$slice_name" in
    *simulator*) src="$SIM_FW" ;;
    *)           src="$TMP/device/eID.framework" ;;
  esac
  rm -rf "$slice/eID.framework"
  cp -R "$src" "$slice/eID.framework"
done

rm -rf "$XC"
mkdir -p "$(dirname "$XC")"
mv "$TMP/eID.xcframework" "$XC"

# The legacy standalone location is now redundant: the device slice lives inside
# the xcframework. Removing it keeps exactly one copy of the 12 MB binary.
if [[ -d "$LEGACY" ]]; then
  log "removing now-redundant ${LEGACY#$REPO/}"
  rm -rf "$LEGACY"
fi

log "done: ${XC#$REPO/}"
plutil -p "$XC/Info.plist" | grep -E 'LibraryIdentifier|SupportedArchitectures|SupportedPlatform' || true
echo
log "simulator slice:"
lipo -info "$XC/ios-arm64_x86_64-simulator/eID.framework/eID"
log "device slice:"
lipo -info "$XC/ios-arm64/eID.framework/eID"
