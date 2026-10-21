#!/usr/bin/env python3
"""Sign the probe for an attached, provisioned device; never export keys."""
import argparse
import datetime
import fnmatch
import hashlib
import plistlib
from pathlib import Path
import re
import shutil
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser()
parser.add_argument('profile', type=Path)
parser.add_argument('--udid', required=True)
parser.add_argument('--app', type=Path, default=ROOT / 'build/LegacyDisplay.app',
                    help='App bundle to sign; IPA is written beside it')
args = parser.parse_args()
app = args.app.resolve()
info = plistlib.loads((app / 'Info.plist').read_bytes())
bundle = info['CFBundleIdentifier']
raw = subprocess.check_output(['security', 'cms', '-D', '-i', str(args.profile)])
profile = plistlib.loads(raw)
assert args.udid in profile.get('ProvisionedDevices', []), 'Profile does not authorize this iPad'
assert profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Expired profile'
entitlements = profile['Entitlements']
prefix = profile['ApplicationIdentifierPrefix'][0]
app_id = prefix + '.' + bundle
assert fnmatch.fnmatchcase(app_id, entitlements['application-identifier']), 'Profile does not authorize this app'
assert entitlements.get('get-task-allow'), 'A development profile is required for launch debugging'
identities = subprocess.check_output(['security', 'find-identity', '-v', '-p', 'codesigning'], text=True)
available = set(re.findall(r'\b[0-9A-F]{40}\b', identities))
certificate_ids = [hashlib.sha1(cert).hexdigest().upper() for cert in profile['DeveloperCertificates']]
identity = next((value for value in certificate_ids if value in available), None)
assert identity, 'No local signing identity matches this profile'
private = ROOT / '.private'
private.mkdir(mode=0o700, exist_ok=True)
signed_entitlements = {
    'application-identifier': app_id,
    'com.apple.developer.team-identifier': entitlements['com.apple.developer.team-identifier'],
    'get-task-allow': True,
    'keychain-access-groups': [app_id],
}
entitlement_path = private / 'development.xcent'
entitlement_path.write_bytes(plistlib.dumps(signed_entitlements))
shutil.copyfile(args.profile, app / 'embedded.mobileprovision')
subprocess.run(['codesign', '--force', '--sign', identity, '--digest-algorithm=sha1,sha256',
                '--entitlements', str(entitlement_path), str(app)], check=True)
subprocess.run(['codesign', '--verify', '--strict', '--verbose=2', str(app)], check=True)
ipa = app.with_suffix('.ipa')
with zipfile.ZipFile(ipa, 'w', zipfile.ZIP_DEFLATED) as archive:
    for path in app.rglob('*'):
        if path.is_file():
            archive.write(path, 'Payload/' + str(path.relative_to(app.parent)))
print(f'Signed and packaged {bundle}: {ipa}')
