# External components and references

The MIT license in this repository applies to this project's original receiver code and documentation.

| Component | Role | Distribution |
| --- | --- | --- |
| [OpenDisplay](https://github.com/peetzweg/opendisplay), GPL-3.0 | Existing Mac sender and published wire-protocol reference; verified with 1.19.0 | Not vendored or redistributed here |
| Apple iOS SDK / UIKit / AVFoundation / CoreMedia / QuartzCore | Compile-time SDK and on-device public frameworks | SDK and framework binaries are not included; Apple's terms apply |
| [theos/sdks](https://github.com/theos/sdks) | Source of the locally prepared legacy SDK stubs | Downloaded separately into ignored `.toolchain/`; consult its license and applicable SDK terms |
| Apple-signed iOS developer disk image | Device-side debugging and screenshots | Obtained separately; not included |
| [libimobiledevice](https://github.com/libimobiledevice/libimobiledevice) / [ideviceinstaller](https://github.com/libimobiledevice/ideviceinstaller) | Pairing, image mounting, installation, launch and screenshots | Installed separately; each tool retains its own license |
| [XcodeGen](https://github.com/yonaskolb/XcodeGen) | Generates a local project for Apple's provisioning workflow | Installed separately |
| [PyYAML](https://github.com/yaml/pyyaml), MIT | Parses local SDK text stubs | Installed separately from the tooling requirements |

This repository contains an independent Objective-C receiver implementation of the published protocol. It does not contain the official Swift receiver or Mac sender. OpenDisplay and Apple product names identify interoperability targets, not affiliation or endorsement.
