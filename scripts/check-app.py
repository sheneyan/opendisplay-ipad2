#!/usr/bin/env python3
"""Validate the actual executable's iOS 9 / armv7 ABI, not its filename."""
from pathlib import Path
import plistlib
import struct
import subprocess

root = Path(__file__).resolve().parents[1]
app = root / 'build/LegacyDisplay.app'
info = plistlib.loads((app / 'Info.plist').read_bytes())
assert info['CFBundleIdentifier'] == 'com.sheneyan.oldipad.display'
assert info['CFBundleExecutable'] == 'LegacyDisplay'
assert info['MinimumOSVersion'] == '9.0'
assert info['UIDeviceFamily'] == [2]
assert not any('$(' in str(value) for value in info.values()), 'Unexpanded Xcode variables in metadata'
data = (app / info['CFBundleExecutable']).read_bytes()
magic, cpu, subtype, kind, commands, command_size, flags = struct.unpack_from('<7I', data)
assert magic == 0xfeedface and cpu == 12 and (subtype & 0xffffff) == 9 and kind == 2, 'Expected armv7 Mach-O executable'
offset = 28
minimum_found = False
for _ in range(commands):
    command, size = struct.unpack_from('<II', data, offset)
    assert size >= 8 and offset + size <= len(data)
    assert command not in (0x32, 0x80000034), 'Modern-only Mach-O load command'
    if command == 0x25:
        minimum, sdk = struct.unpack_from('<II', data, offset+8)
        assert minimum == 0x00090000 and sdk == 0x00090300
        minimum_found = True
    offset += size
assert minimum_found, 'Missing LC_VERSION_MIN_IPHONEOS'
subprocess.run(['plutil', '-lint', str(app / 'Info.plist')], check=True)
print('PASS: armv7 executable, iOS 9.0 minimum, iOS 9.3 SDK, iPad metadata, legacy Mach-O commands')
