#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your existing Apple development team ID}"
: "${DEVICE_UDID:?Set DEVICE_UDID to the attached iPad identifier from idevice_id -l}"
BUILD_ARCH="${BUILD_ARCH:-armv7}"
case "$BUILD_ARCH" in
  armv7) MIN_IOS=9.0 ;;
  arm64) MIN_IOS=12.0 ;;
  *) echo 'BUILD_ARCH must be armv7 or arm64' >&2; exit 1 ;;
esac
mkdir -p "$ROOT/.private"
chmod 700 "$ROOT/.private"
cd "$ROOT"
# Xcode filters device destinations using the generated project's architecture
# before applying command-line build overrides. Generate the matching helper.
python3 - "$BUILD_ARCH" "$MIN_IOS" <<'PY'
from pathlib import Path
import sys
text = Path('project.yml').read_text()
text = text.replace('ARCHS: armv7', 'ARCHS: ' + sys.argv[1])
text = text.replace("iOS: '9.0'", "iOS: '" + sys.argv[2] + "'")
Path('.private/provision-project.yml').write_text(text)
PY
xcodegen generate --spec .private/provision-project.yml --project-root "$ROOT" --project "$ROOT"
# This modern-Xcode project is used for portal registration/provisioning only.
# Use the selected build script's output for installation; armv7 build rejection
# after successful provisioning is expected with modern Xcode.
xcodebuild -project LegacyDisplay.xcodeproj -scheme LegacyDisplay \
  -destination "id=$DEVICE_UDID" -derivedDataPath build/xcode \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" -allowProvisioningUpdates \
  ARCHS="$BUILD_ARCH" VALID_ARCHS="$BUILD_ARCH" IPHONEOS_DEPLOYMENT_TARGET="$MIN_IOS" \
  -allowProvisioningDeviceRegistration build > .private/provision.log 2>&1 || true
python3 - <<'PY'
import datetime, fnmatch, os, pathlib, plistlib, subprocess
profiles = pathlib.Path.home() / 'Library/Developer/Xcode/UserData/Provisioning Profiles'
for path in sorted(profiles.glob('*.mobileprovision'), key=lambda p: p.stat().st_mtime, reverse=True):
    result = subprocess.run(['security', 'cms', '-D', '-i', str(path)], capture_output=True)
    if result.returncode:
        continue
    profile = plistlib.loads(result.stdout)
    entitlements = profile['Entitlements']
    app_id = profile['ApplicationIdentifierPrefix'][0] + '.com.sheneyan.oldipad.display'
    if (os.environ['DEVICE_UDID'] in profile.get('ProvisionedDevices', [])
        and entitlements.get('get-task-allow')
        and entitlements.get('com.apple.developer.team-identifier') == os.environ['DEVELOPMENT_TEAM']
        and profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None)
        and fnmatch.fnmatchcase(app_id, entitlements.get('application-identifier', ''))):
        print('Device-authorized development profile:')
        print(path)
        break
else:
    raise SystemExit('No matching profile was created. Inspect .private/provision.log and Xcode Accounts.')
PY
