# Handoff — October 21, 2026

## Result

The non-jailbroken iPad 2 path works on the tested hardware. A development-signed armv7 app installs and launches on iOS 9.3.5, then receives H.264 from the unmodified OpenDisplay 1.19.0 Mac sender over USB.

Verified display configuration: M1 MacBook Air internal display, existing 1920x1080 physical monitor, and a separate OpenDisplay iPad desktop. All three were online and unmirrored. Build 4 requests 1280x960 logical points, with a 2560x1920 HiDPI backing display and an independently capped 1024x768 encoded stream. Builds 1–3 requested 1024x768 logical points.

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

## Build 4 desktop-size trial

The user approved trying 1280x960 logical desktop space with unchanged 1024x768 transport. Only the legacy hello desktop-size fields and build number changed; physical panel facts and decode limits remain unchanged. Build 3's signed IPA was retained locally for rollback. Build 4 compiled, passed binary checks, was signed and installed on the iPad. macOS reported a 1280x960 logical desktop (2560x1920 backing), and sender logs confirmed a 1024x768 H.264 stream. All three displays remained online and unmirrored. A device screenshot of the visual smoke window showed 12/16/24 pt text, color blocks and the advancing counter at 8.3 seconds; the receiver reported 253 submitted frames and zero errors. Subjective readability remains a user evaluation; this change does not increase physical display resolution.

## Build 5 clean display

The diagnostics label is hidden; desktop sizing and video limits are unchanged. Build 5 passed compilation, armv7/iOS metadata checks and signature verification, then installed and launched on the iPad. A fresh USB screenshot confirmed the received desktop has no bottom diagnostics overlay. GitHub About now describes the native iOS 9 / armv7 USB receiver, no-jailbreak operation and MIT license in English, with relevant repository topics.

## iPad mini 2 installation and public guide

The second USB device was identified directly as `iPad4,4`, iOS 12.5.8 (16H88), arm64: an iPad mini 2 Wi-Fi. Its OS cannot launch the existing 32-bit package. `scripts/build-arm64.sh` builds the unchanged receiver source with Xcode's current iPhoneOS SDK and an iOS 12.0 deployment target, into `build/arm64/`. The accepted armv7 Build 5 package and installed iPad 2 app remain intact. `sign.py --app` selects the bundle and writes its IPA beside it.

Pairing required the user to accept Trust on the mini. The device accepted the Apple-signed 12.4 (16G73) developer disk image. Xcode initially excluded the device because the provisioning helper declared armv7; command-line architecture overrides alone did not resolve destination filtering. `provision.sh` now generates an ignored helper spec for `BUILD_ARCH=armv7` (default) or `arm64` before invoking Xcode. The arm64 route successfully registered/provisioned this mini using the existing account.

The arm64 Build 5 package passed signing verification, installation and launch, then connected to the unmodified OpenDisplay 1.19.0 sender. Host logs confirmed a 1280x960 logical desktop and 1024x768 H.264 capture. Host display enumeration showed four online, unmirrored displays: the Mac internal panel, physical external monitor, iPad 2 and mini 2. A temporary copy of the smoke tool targeted the mini's exact display ID; two USB screenshots confirmed the test text, color blocks and advancing counter without a diagnostics strip. No physical FPS, latency, full Retina stream or long-duration stability claim is made.

The English README now walks through sender setup, architecture selection, tools, SDKs, device trust, provisioning, signing, installation, daily use, reconnects, expiration and troubleshooting. Only the two device/OS combinations above are hardware-verified. Raw mini screenshots and diagnostics remain under ignored `build/evidence/` and `.private/`.

## Build 6 resolution controls

The user requested independent resolution choice on the mini 2. The arm64 build now enables a one-second long press menu with separate desktop presets (1024x768 through 4096x3072) and video ceilings (1024x768 through 2048x1536). Selections persist in NSUserDefaults and reconnect the receiver. The armv7 build retains its fixed 1280x960 desktop / 1024x768 stream. Physical panel metadata now distinguishes these build targets. The final Build 6 default is 1280x960 desktop with a 2048x1536 video ceiling.

The real TCP handshake test first failed against the old fixed settings, then passed after implementation. Both legacy and expanded test variants cover independent selections, maximum desktop negotiation, invalid saved values, physical panel facts and ten immediate listener restart cycles. Both architectures compile, and the armv7 binary metadata check passes. The arm64 Build 6 was signed, installed and launched on the mini; the installed iPad 2 app remains Build 5.

An initial 2048x1536 desktop / 2048x1536 video attempt created a virtual display object but never reached an online capturable screen. Later native UI inspection reported that the Mac was locked and automatic unlock failed. This confounds the attempt: do not claim that resolution exceeds a hardware limit, or that captured stale desktop pixels prove native video decoding. The latest installed package defaults to the previously working desktop size, but the sender may need its mini-only Refresh/Disconnect/Connect after unlocking.

The Mac-unlock follow-up below supersedes the initial blocked test. Build 7 subsequently passed the settings UI and 1600x1200 desktop reconfiguration check. Raw evidence stays under ignored `build/evidence/`.

## Build environment

- Xcode 26.6 clang and `ld-classic`, invoked directly because modern Xcode's build system rejects armv7.
- iOS 9.3 SDK from theos/sdks revision `0222fd5413cf4b9af096f37b4621afa2688572f7`, prepared locally by `scripts/prepare-sdk.py`.
- libimobiledevice 1.4.0, ideviceinstaller 1.2.0, XcodeGen and PyYAML 6.0.3.
- The generated Xcode project is a provisioning helper, not the production build route.

## Current limitations

- USB and landscape only. Build 8 adds touch input; no audio, HEVC or portrait switching.
- Build 5 hides the diagnostics strip so it no longer covers the received image.
- OpenDisplay 1.19.0 ignores the receiver's advertised 30 fps ceiling. Submitted-frame counters are not physical display FPS measurements.
- After exiting the receiver, manually click Connect in the sender if necessary. Automatic app-exit reconnect is not claimed.
- Actual cable unplug/replug, thermal behavior, extended daily use, physical end-to-end latency and other iPad models are unverified.
- Source compiles and runs on the tested setup; this is not a claim that all Xcode versions retain an armv7-capable linker. The arm64 route uses the current Xcode SDK and a separate output directory.

## Next work, only if requested

1. Check daily-use stability and cable unplug/replug on the actual device.
2. Validate iPad mini 1 on real hardware before advertising support.
3. Add portrait support or additional gestures only as separately requested changes.

## Mac launcher for an unresponsive iPad 2 Home button

`scripts/launch.sh DEVICE_UDID DEVELOPER_IMAGE` targets an exact USB device, mounts the matching developer disk image if absent, launches the installed receiver with `idevicedebug --detach`, and opens the Mac sender. It does not reinstall the app or change display settings. The Mac shortcut uses a standalone launcher under `$HOME/Library/Application Support/Legacy Display/`, with the device identifier in a local configuration file and the developer image beside it. The ignored `.private/launchers/` wrapper forwards to that location. Neither the shortcut nor its launcher hardcodes a username or checkout path; public source contains no device identifier.

On October 21, the attached iPad 2 initially reported no developer image. Mounting its existing iOS 9.3 image and launching succeeded. Fresh sender logs confirmed an online 1280x960 desktop and 1024x768 H.264 capture; a USB screenshot confirmed the received desktop. The launcher also passed shell syntax validation and rejected a nonexistent USB target.

The user explicitly approved enabling Shortcuts' global Allow Running Scripts setting. A native Mac shortcut named `启动 iPad 2 副屏` now calls the standalone launcher using `$HOME`, with Show in Spotlight enabled and administrator execution off. Running it from the Shortcuts editor produced the launcher's successful completion output. Unlocking the physical iPad and keeping the development signature valid are still required.

### Build 6 follow-up after Mac unlock

The user unlocked the Mac and reported that long press seemed unresponsive. Inspection confirmed installed Build 6 and the expected gesture/menu selectors in the arm64 executable. The Mac sender reported the mini receiver asleep/backgrounded; a fresh remote launch reopened it. On the unlocked Mac, the 1280x960 desktop came online and the sender logged a 2048x1536 H.264 capture. A fresh screenshot (`mini-native-unlocked-test.png`) shows the smoke window's text/color blocks and counter at 19.5 seconds, proving actual native-sized video reception rather than only negotiation.

### Build 7 settings presentation correction

The user confirmed that a direct long press on the mini opens Display Settings, but tapping Desktop Size did nothing. The previous implementation chained alert controllers and explicitly dismissed the root controller while UIKit was already dismissing the selected alert action. Build 7 replaces that flow with one grouped table in a navigation form sheet. Desktop Size and Video Quality are sections with directly selectable resolution rows, persistent checkmarks and a Done button; no nested alert presentation remains.

Build 7 compiled for both architectures, passed the armv7 metadata check and `git diff --check`, and the arm64 package passed signing verification, installation and remote launch. Device package enumeration confirms installed version 7 on the mini. The iPad 2 remains on its accepted Build 5. The underlying settings/handshake tests had already passed both legacy and expanded variants before this UIKit-only correction.

The user confirmed that the Build 7 list appeared and 1600x1200 was checked. Fresh sender logs at 14:30:01–14:30:03 show the receiver reconnecting, a 3200x2400 hello, an online 1600x1200-point virtual display, and a 2048x1536 H.264 capture. Host display enumeration independently confirms the logical dimensions and Mirror Off, with the internal panel and existing physical monitor still online. A mini USB screenshot (`mini-build7-1600.png`) shows the targeted smoke window's text, color blocks and animated counter at 9.1 seconds. This verifies long press → select → reconnect → actual displayed result. All three protocol/transport test variants passed again after the device acceptance.

Remaining verification boundaries: higher desktop presets, changing Video Quality through the physical UI, and selection persistence across a full app relaunch have not been separately exercised. Independent preferences and invalid-value fallback are covered by real TCP hello tests. Long-duration performance is unmeasured. These are not prerequisites to publishing the now-verified 1600x1200 settings path, and the README explicitly labels the larger presets experimental.

## Build 8 touch controls

The user requested tap, drag and two-finger scrolling on both devices while retaining the mini settings hold. The client implements the published OpenDisplay 1.19.0 pv3 `touch` / `scroll` messages independently. `ODTouchInput` owns gesture arbitration and aspect-fit mapping; `ODTouchView` adapts UIKit contacts and the one-second mini timer. Taps commit on lift, movement of eight view points starts a drag, and a second contact cancels a drag before scrolling. Remaining contacts must lift before a new click. A mini settings hold emits no mouse press.

The receiver sends input on its existing serial queue. Gesture messages carry the connection session captured at contact start, so stale input cannot control a new session. Active mouse-down state is released before receiver stop/disconnect; the UIKit gesture is cancelled on backgrounding, session reset and video geometry changes. Scroll deltas use decoded-video pixels; touch coordinates are normalized within the actual aspect-fit image.

Tests first demonstrated missing tap output and missing session-bound transport, then passed after implementation. The full sanitizer suite covers gesture transitions, aspect-fit/letterbox mapping, clamping, long-press suppression, cancellation, real TCP input messages, stale-session rejection and release-before-sleep over ten reconnects in both build variants. Both architectures compiled; legacy binary checks and development signature verification passed. Previous signed Build 5 (iPad 2) and Build 7 (mini) packages remain local for rollback.

Both actual devices report installed Build 8. Live sender sessions report iPad 2 at 1280x960 desktop / 1024x768 H.264 and mini 2 at 1600x1200 desktop / 2048x1536 H.264. The existing internal and physical external displays remain online and unmirrored. `scripts/touch-smoke.swift` creates its own temporary target windows and records received events to an ignored local JSONL file; it does not synthesize input or move existing windows. Device screenshots show nonzero tap, drag and scroll counters on each window. The user confirmed that both devices were operated directly by finger: taps, drags and two-finger scrolling reached the target windows. On mini 2, a stationary one-second hold opened Display Settings, and closing it did not increase the Tap counter. These physical acceptance checks passed.

## USB interruption recovery and restart launcher

After Build 8 acceptance, the user reported repeated charging sounds and a frozen image. The sender log recorded rapid USB detach/attach events around 18:45, followed by session expiry. This establishes transport interruption, but does not identify whether the cable, connector, power, or another USB-level condition caused it. At inspection the exact iPad 2 was reachable on iOS 9.3.5, charging at 75%, with its developer image mounted.

The launcher now requests `idevicedebug kill` before detached launch. Each debug command is bounded to 20 seconds using the system Perl alarm; USB discovery/image listing are bounded to 15 seconds and image mounting to 60 seconds. libimobiledevice 1.4.0 leaves the kill command's default return value at -1 even on the successful path ([upstream implementation](https://github.com/libimobiledevice/libimobiledevice/blob/1.4.0/tools/idevicedebug.c#L464)), so status 255 is tolerated but is not treated as independent proof of termination. A USB screenshot after the stop command confirmed the iPad Home screen. The standalone launcher used by the existing Shortcuts entry was updated in place, preserving its local device configuration and path-independent wrapper.

Four isolated launcher regression tests cover stop-before-start with legacy status 255, missing device, failed launch, and stop-timeout handling. The tests first failed for missing stop behavior, then passed. Shell syntax and diff checks passed; a separate real one-second alarm test terminated a five-second sleeping command. Running the deployed shortcut wrapper succeeded. Subsequent device screenshots showed the live acceptance animation progressing from 2.9 to 26.4 seconds on the 1280x960 desktop / 1024x768 stream. The temporary test window closed automatically. This verifies recovery after restart, not a permanent fix for USB instability.
