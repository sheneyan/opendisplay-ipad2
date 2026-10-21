#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SDK="${LEGACY_IOS_SDK:-$ROOT/.toolchain/prepared/iPhoneOS9.3.sdk}"
APP="$ROOT/build/LegacyDisplay.app"
test -d "$SDK/System/Library/Frameworks/UIKit.framework/Headers" || { echo 'Missing legacy SDK' >&2; exit 1; }
mkdir -p "$APP" "$ROOT/build/objects"
objects=()
for source in "$ROOT"/app/*.m "$ROOT"/app/*.c; do
  object="$ROOT/build/objects/$(basename "${source%.*}").o"
  options=(-fblocks)
  if [[ "$source" == *.m ]]; then options+=(-fobjc-arc); fi
  xcrun clang -target armv7-apple-ios9.0 -isysroot "$SDK" "${options[@]}" \
    -Os -Wall -Wextra -Werror -Wno-unused-parameter -c "$source" -o "$object"
  objects+=("$object")
done
xcrun ld-classic -arch armv7 -iphoneos_version_min 9.0 -syslibroot "$SDK" \
  -framework UIKit -framework Foundation -framework CoreGraphics \
  -framework AVFoundation -framework CoreMedia -framework QuartzCore -lSystem -lobjc \
  "${objects[@]}" -o "$APP/LegacyDisplay"
cp "$ROOT/app/Info.plist" "$APP/Info.plist"
printf 'APPL????' > "$APP/PkgInfo"
file "$APP/LegacyDisplay"
xcrun otool -l "$APP/LegacyDisplay" | sed -n '/LC_VERSION_MIN_IPHONEOS/,+4p'
