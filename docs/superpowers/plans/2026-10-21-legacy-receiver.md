# Legacy receiver implementation plan

**Goal:** Install and launch a non-jailbroken armv7 probe on this iPad, then validate an OpenDisplay-compatible receiver as an additional extended display.

**Architecture:** Separate build/sign/install tooling from a small UIKit app. Keep protocol framing and Annex B conversion independent of the device listener and rendering view.

**Tech Stack:** Objective-C, UIKit, CoreMedia, AVFoundation, BSD sockets; Xcode clang/ld-classic with legacy SDK; libimobiledevice for installation.

## Gate 1: toolchain and install

- [ ] Obtain legacy SDK under `.toolchain/`; record its source and revision. Confirm linker armv7 support with `xcrun ld-classic -arch armv7 -v`.
- [ ] Add a minimal launch probe in `app/main.m`, app metadata in `app/Info.plist`, and a reproducible script in `scripts/build.sh`. Verify with `file`, `otool -l`, and `codesign --verify`.
- [ ] Use existing signing identity and a device-authorized provisioning profile. Existing cached profiles omit the iPad. Register/provision using the configured developer account if possible; do not extract keys or revoke certificates.
- [ ] Install using `ideviceinstaller`, verify the bundle in the device app inventory, launch with developer tooling if supported, and capture launch evidence. If device/account confirmation is required, identify it exactly.

## Gate 2: protocol and video

- [ ] Add `tests/protocol_tests.c` with split-header, coalesced-frame, invalid-length, and Annex B sample conversion cases; verify failures before implementing `app/ODProtocol.c`.
- [ ] Implement device-side port 9000 listener and pv3 hello/ping/kf in `app/ODReceiver.m`. Build with iOS 9 APIs and a stable per-install identity.
- [ ] Implement SPS/PPS handling, Annex B to AVCC conversion, and sample-buffer presentation in `app/ODVideoView.m`. Release old decode state on reconnect and request IDR on failures.
- [ ] Sign, reinstall, launch; connect the existing OpenDisplay sender. Record independent virtual-display enumeration and device rendering evidence. Constrain Mac changes to a separate development build only if real decoder evidence requires them.

## Gate 3: acceptance and handoff

- [ ] Verify existing external display remains extended, iPad gets a separate desktop, windows move onto it, display is readable, and reconnect restores rendering.
- [ ] Record successful commands, versions, verified gates, and remaining limitations in `README.md` and `HANDOFF.md`. No success claim without corresponding current evidence.
