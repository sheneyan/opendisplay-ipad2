#!/bin/bash
# Separate iOS 12+ build; leaves the verified iOS 9 / armv7 output untouched.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="$(xcrun --sdk iphoneos --show-sdk-path)"
OUT="$ROOT/build/arm64"
APP="$OUT/LegacyDisplay.app"
mkdir -p "$APP" "$OUT/objects"
objects=()
for source in "$ROOT"/app/*.m "$ROOT"/app/*.c; do
  object="$OUT/objects/$(basename "${source%.*}").o"
  options=(-fblocks -DOD_RETINA_SETTINGS=1)
  if [[ "$source" == *.m ]]; then options+=(-fobjc-arc); fi
  # These legacy APIs are intentional: the app must still run on iOS 12.
  xcrun clang -target arm64-apple-ios12.0 -isysroot "$SDK" "${options[@]}" \
    -Os -Wall -Wextra -Werror -Wno-unused-parameter -Wno-deprecated-declarations \
    -c "$source" -o "$object"
  objects+=("$object")
done
xcrun clang -target arm64-apple-ios12.0 -isysroot "$SDK" "${objects[@]}" \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -framework AVFoundation -framework CoreMedia -framework QuartzCore \
  -o "$APP/LegacyDisplay"
cp "$ROOT/app/Info.plist" "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :MinimumOSVersion 12.0' "$APP/Info.plist"
/usr/libexec/PlistBuddy -c 'Set :UIRequiredDeviceCapabilities:0 arm64' "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"
file "$APP/LegacyDisplay"
xcrun otool -l "$APP/LegacyDisplay" | sed -n '/LC_BUILD_VERSION/,+6p; /LC_VERSION_MIN_IPHONEOS/,+4p'
