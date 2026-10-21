# Handoff — October 21, 2026

## Result

The non-jailbroken iPad 2 path works on the tested hardware. A development-signed armv7 app installs and launches on iOS 9.3.5, then receives H.264 from the unmodified OpenDisplay 1.19.0 Mac sender over USB.

Verified display configuration: M1 MacBook Air internal display, existing 1920x1080 physical monitor, and a separate OpenDisplay iPad desktop. All three were online and unmirrored. The iPad desktop is 1024x768 logical points, with a 2048x1536 HiDPI backing display and an independently capped 1024x768 encoded stream.

## Evidence

- The real device passed USB pairing and accepted the iOS 9.3 developer disk image.
- A matching development profile was created through Xcode's existing authenticated account. No private keys were exported, no jailbreak was performed, and no firmware was changed.
- Build 1 installed and launched as a minimal UIKit probe. A USB screenshot confirmed the launch text.
- Build 2 installed and launched the actual receiver. Screenshots showed the Mac desktop and TCP cursor overlay, H.264 profile 100 / level 3.2, and zero display-layer errors.
- The visual smoke test moved its own window to the independent iPad desktop and displayed 12/16/24 pt text, color blocks, an advancing counter and moving block. The receiver's error counter stayed at zero in the captured samples.
- Force-terminating the receiver removed only its virtual display; the two existing displays remained online and unmirrored. Relaunching the receiver and selecting Connect in the Mac sender restored the third display.
- Protocol tests passed with AddressSanitizer and UndefinedBehaviorSanitizer. The actual binary was checked for armv7, iOS 9.0 minimum, SDK 9.3, metadata and legacy load commands.
- Review found a listener shutdown/restart race. A regression test against the real transport reproduced `EADDRINUSE` before the fix, then passed ten immediate stop/start cycles and fresh socket handshakes after the fix. Build 3 contains this correction.
- The final Build 3 was development-signed, installed, launched and reconnected to the unmodified sender. A fresh device screenshot showed H.264 1024x768, profile 100 / level 3.2, and zero errors; fresh host enumeration again confirmed three online, unmirrored displays.

Raw device screenshots and host logs remain local under ignored `build/evidence/`. Provisioning output and entitlements remain under ignored `.private/`. Never publish profiles, developer credentials, UDIDs or a device-specific signed IPA.

## Build environment

- Xcode 26.6 clang and `ld-classic`, invoked directly because modern Xcode's build system rejects armv7.
- iOS 9.3 SDK from theos/sdks revision `0222fd5413cf4b9af096f37b4621afa2688572f7`, prepared locally by `scripts/prepare-sdk.py`.
- libimobiledevice 1.4.0, ideviceinstaller 1.2.0, XcodeGen and PyYAML 6.0.3.
- The generated Xcode project is a provisioning helper, not the production build route.

## Current limitations

- USB and landscape only. No touch, audio, HEVC or portrait switching.
- A small status strip covers the bottom of the received image.
- OpenDisplay 1.19.0 ignores the receiver's advertised 30 fps ceiling. Submitted-frame counters are not physical display FPS measurements.
- After exiting the receiver, manually click Connect in the sender if necessary. Automatic app-exit reconnect is not claimed.
- Actual cable unplug/replug, thermal behavior, extended daily use, physical end-to-end latency and other iPad models are unverified.
- Source compiles and runs on the tested setup; this is not a claim that all Xcode versions retain an armv7-capable linker.

## Next work, only if requested

1. Check daily-use stability and cable unplug/replug on the actual device.
2. Make the diagnostics strip optional.
3. Validate iPad mini 1 on real hardware before advertising support.
4. Add touch input or portrait support as separate, explicitly scoped changes.
