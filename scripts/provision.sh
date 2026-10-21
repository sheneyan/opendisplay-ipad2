#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
: "${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM to your existing Apple development team ID}"
: "${DEVICE_UDID:?Set DEVICE_UDID to the attached iPad identifier from idevice_id -l}"
mkdir -p "$ROOT/.private"
chmod 700 "$ROOT/.private"
cd "$ROOT"
xcodegen generate
# This modern-Xcode project is used for portal registration/provisioning only.
# Xcode's subsequent armv7 rejection is expected; build.sh builds the real app.
xcodebuild -project LegacyDisplay.xcodeproj -scheme LegacyDisplay \
  -destination "id=$DEVICE_UDID" -derivedDataPath build/xcode \
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM" -allowProvisioningUpdates \
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
