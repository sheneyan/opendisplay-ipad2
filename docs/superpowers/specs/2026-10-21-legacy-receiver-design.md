# iPad 2 OpenDisplay receiver

Approved in chat on 2026-10-21. Target: attached iPad2,1 on iOS 9.3.5 (13G36), M1 MacBook Air on macOS 26.5, OpenDisplay 1.19.0. Prefer installation without jailbreak. Preserve the existing physical external display and installed OpenDisplay.

## Ordered acceptance gates

1. Build a real armv7 UIKit application with minimum iOS 9.0. Sign with an existing development identity and a profile authorizing this device and a new app identifier. Install and launch it on the attached iPad without jailbreak. Compilation alone does not pass this gate.
2. Implement OpenDisplay pv3 framing and hello/ping/keyframe control over a device-side TCP listener on port 9000. Parse Annex B H.264 into CoreMedia samples for AVSampleBufferDisplayLayer. First target landscape 1024x768; decoder profile/rate support requires device evidence.
3. Connect the installed Mac OpenDisplay over USB. Verify a distinct extended desktop coexists with the existing display, window movement, readable output, disconnect/reconnect, and actual presentation on the iPad.

## Constraints

UIKit and Objective-C replace SwiftUI/Network/Combine. No HEVC, Metal, touch input, or rotation in the first slice. No jailbreak, restore, firmware update, certificate replacement/revocation, or changes to other apps. Keep SDK downloads, profiles, device identifiers and signing artifacts out of Git. Use local existing credentials without extracting private keys. If account authentication or an on-device confirmation is necessary, report the exact step and continue independent work.

## Known risks

Current Xcode officially dropped armv7 builds, but its clang target and ld-classic may still be usable with a legacy SDK; prove this directly. Cached profiles do not include the attached iPad, so provisioning must be updated before a non-jailbroken install. OpenDisplay 1.19.0 fixes its expected encoding rate at 60 fps and uses H.264 High AutoLevel. A receiver-only implementation may require a narrowly scoped Mac sender adjustment if real decoding fails. Do not assume dropping arbitrary compressed P-frames is valid.
