# OpenDisplay iPad 2 Receiver

A small, independent receiver for the [OpenDisplay protocol](https://github.com/peetzweg/opendisplay/blob/v1.19.0/PROTOCOL.md). It lets an old iPad display an additional Mac desktop over USB, without jailbreaking the iPad. The original build targets **iOS 9 / armv7**; a separate **iOS 12 / arm64** build uses the same receiver source.

This is an experimental third-party receiver, not an official OpenDisplay release. The Mac runs the existing OpenDisplay sender; no sender modification was needed for the verified configuration.

## Start here

This is a **build-and-sign guide**, not an App Store installation. You need a Mac with Xcode, a USB data cable, the iPad's unlock code, and your own Apple development signing identity/profile. There is no universally installable IPA: the signed package must authorize your specific iPad.

Follow the numbered steps below in order. Run terminal commands from the cloned repository directory. Values such as `YOUR_IPAD_UDID`, `YOUR_TEAM_ID` and `/path/to/...` are placeholders you must replace locally. Do not post them in public issues.

| Device/system | Build route | Status |
| --- | --- | --- |
| iPad 2 Wi-Fi, iOS 9.3.5 | `scripts/build.sh` (armv7) | Verified on hardware |
| Original iPad mini, iOS 9 | armv7 candidate | Not tested; similar hardware alone is not validation |
| iPad mini 2 Wi-Fi, iOS 12.5.8 | `scripts/build-arm64.sh` (arm64) | Verified on hardware |
| iOS earlier than 9 | Neither route | Unsupported by this project |
| iOS 11 or later with the armv7 package | Do not install that package | iOS 11 removed 32-bit app support; an arm64 build is required |

The arm64 script targets iOS 12 and later, but that deployment target is not a compatibility guarantee for every newer iPad or OS. The current armv7 build is not a solution for an iPad mini 2/3 running iOS 12. See [Apple's 32-bit compatibility note](https://developer.apple.com/library/archive/qa/qa1971/_index.html).

## Verified configuration

Tested on October 21, 2026:

| Component | Verified configuration |
| --- | --- |
| Receiver A | iPad 2 Wi-Fi (`iPad2,1`), iOS 9.3.5 (13G36), armv7, no jailbreak |
| Receiver B | iPad mini 2 Wi-Fi (`iPad4,4`), iOS 12.5.8 (16H88), arm64, no jailbreak |
| Host | M1 MacBook Air, macOS 26.5 (25F71) |
| Sender | OpenDisplay 1.19.0 |
| Connection | USB / macOS usbmuxd |
| Extended desktop | 1280 × 960 logical points; sender creates a 2560 × 1920 HiDPI backing display (Build 4 and later) |
| Original video baseline | 1024 × 768 H.264 High Profile, Level 3.2 (Build 5 on both devices) |
| Display coexistence | Mac internal display + existing 1920 × 1080 physical monitor + iPad 2 + iPad mini 2, four online displays, all unmirrored |

The app was compiled, development-signed, installed and launched on the real iPad. Device screenshots verified a moved test window, 12/16/24 pt text, color blocks, an animated counter and a cursor. The display layer reported zero errors during these checks. The submitted-frame counter is **not a measurement of physical display FPS or latency**.

The iPad mini 2 separately passed arm64 build, signing, installation, launch and USB display checks with Build 5. Device screenshots confirmed the text/color test window and advancing animation counter, with no diagnostics overlay. The Build 5 mini trial used a 1024 × 768 stream ceiling. Build 6 later displayed a 2048 × 1536 H.264 stream on the real mini at a 1280 × 960 logical desktop after unlocking the Mac, with the text/color/animation test visible in a USB screenshot. Long-duration use remains untested. The zero-error-counter observation above refers to the earlier iPad 2 diagnostics checks.

Force-quitting and relaunching the receiver, then clicking **Connect** in OpenDisplay on the Mac, restored the extended display. Automatic reconnection after an app exit is not guaranteed by the tested sender. Cable unplug/replug and long-duration use have not been tested.

The armv7 builds from Build 4 onward request a larger 1280 × 960 desktop while retaining the 1024 × 768 video ceiling and physical panel dimensions. The Mac scales the desktop into the video stream: this provides more workspace, not more physical pixels. Text becomes smaller and may appear soft. OpenDisplay's connection status reports the video size; macOS display settings report the logical desktop size. Builds 1–3 requested a 1024 × 768 desktop. The legacy sizing fields target OpenDisplay 1.19.0. Build 6 reports the mini 2 panel as 2048 × 1536 at 2x in the arm64 build; newer senders have not been validated.

## Current scope

- USB only; the receiver listens on loopback TCP port 9000, with no Wi-Fi listener.
- Landscape, full-screen video and TCP cursor overlay. The diagnostics strip is hidden in Build 5 and later.
- H.264 only. The armv7 build keeps its 1024 × 768 video ceiling; the arm64 build offers selectable video ceilings through 2048 × 1536.
- No touch input, audio, Pencil, HEVC, portrait switching or background streaming.
- Keeping the app in the foreground disables auto-lock; leaving the app tears down the receiver.

The receiver advertises a 30 fps capability for newer senders. **OpenDisplay 1.19.0 ignores that capability and still uses its own nominal 60 fps pipeline.** Do not describe this test as a verified 30 or 60 fps presentation result.

## 1. Prepare the Mac sender

1. Install and open the Mac sender from [OpenDisplay's releases](https://github.com/peetzweg/opendisplay/releases/tag/v1.19.0). Version **1.19.0** is the version tested here; later releases may negotiate display size differently.
2. Grant **Screen Recording** when prompted so OpenDisplay can capture the desktop. Follow its restart prompt if one appears. Accessibility is used by the sender's input features; this receiver currently has no touch input.
3. Choose **Extend** in OpenDisplay to create an independent desktop.
4. Leave OpenDisplay running while you set up the iPad receiver. The official modern iPad app is not needed; this guide installs **Legacy Display** instead.

## 2. Install build tools and get the source

- macOS, a full Xcode installation and command-line tools. Tested with Xcode 26.6.
- For armv7: Xcode's `clang` ARM backend and `ld-classic`. Although Xcode's normal build system rejects armv7, these tools can still build it directly with a legacy SDK.
- For armv7: an iOS 9.3 SDK obtained under the applicable SDK terms. SDKs and developer disk images are not distributed in this repository. The arm64 route uses the SDK bundled with Xcode.
- Python 3 and PyYAML for preparing the legacy SDK's text stubs.
- An existing Apple development signing identity and a development provisioning profile authorizing both this app and this iPad. Jailbreak or ad-hoc code signing alone is not sufficient.

Open Xcode once and complete its first-launch setup. Confirm `xcode-select -p` points to the full Xcode installation, not only Command Line Tools. If necessary, select your installation with `sudo xcode-select --switch /Applications/Xcode.app/Contents/Developer`.

The verified setup used an existing development team and matching certificate in Keychain. In Xcode, add your account under **Settings → Accounts** and use **Manage Certificates** if you need an Apple Development certificate. Free Personal Team provisioning has not been validated with this legacy workflow. Apple's [account documentation](https://developer.apple.com/help/account/basics/about-your-developer-account) says Personal Team profiles expire after seven days; do not assume a one-time installation will work indefinitely.

Install the device tools and project generator:

```bash
brew install libimobiledevice ideviceinstaller xcodegen
git clone https://github.com/sheneyan/opendisplay-ipad2.git
cd opendisplay-ipad2
```

## 3. Build the correct architecture

### Route A: iPad 2 / armv7 / iOS 9

The verified SDK source is [theos/sdks](https://github.com/theos/sdks) at revision `0222fd5413cf4b9af096f37b4621afa2688572f7`. Only the `iPhoneOS9.3.sdk` directory is used. No jailbreak tooling runs on the device.

```bash
mkdir -p .toolchain/sdks
git -C .toolchain/sdks init
git -C .toolchain/sdks remote add origin https://github.com/theos/sdks.git
git -C .toolchain/sdks sparse-checkout init --cone
git -C .toolchain/sdks sparse-checkout set iPhoneOS9.3.sdk
git -C .toolchain/sdks fetch --depth 1 origin 0222fd5413cf4b9af096f37b4621afa2688572f7
git -C .toolchain/sdks checkout --detach FETCH_HEAD
python3 -m venv .toolchain/venv
.toolchain/venv/bin/pip install -r requirements-tooling.txt
.toolchain/venv/bin/python scripts/prepare-sdk.py
```

The preparation script makes a local copy. It selects existing armv7 exports to avoid modern TAPI misclassifying mixed device/simulator stubs, removes a dangling `liblaunch` re-export, and restores missing declarations for the standard C functions `memcpy` and `memchr`. It does not install replacement libraries on the iPad or alter Xcode.

Build and validate the armv7 app:

```bash
bash scripts/test.sh
bash scripts/build.sh
python3 scripts/check-app.py
```

`build/LegacyDisplay.app/LegacyDisplay` must be a 32-bit armv7 Mach-O executable with `LC_VERSION_MIN_IPHONEOS` set to iOS 9.0 and SDK 9.3. The build treats compiler warnings as errors. Tests run on the Mac with AddressSanitizer and UndefinedBehaviorSanitizer. The listener regression test exercises the real transport on loopback port 9000 through ten immediate stop/start cycles; keep that host port free while testing.

For the remaining steps, select this output:

```bash
export APP_PATH="$PWD/build/LegacyDisplay.app"
export BUILD_ARCH=armv7
```

### Route B: 64-bit iPad / iOS 12

Skip the legacy SDK download/preparation above. Build with the current Xcode SDK:

```bash
bash scripts/test.sh
bash scripts/build-arm64.sh
export APP_PATH="$PWD/build/arm64/LegacyDisplay.app"
export BUILD_ARCH=arm64
```

The script prints `arm64` and a minimum OS of `12.0`. This separate output directory preserves the armv7 build. Build 7 enables the mini 2 resolution settings described below. The diagnostics overlay remains hidden.

## 4. Pair the iPad and create its signing profile

Unlock the iPad, connect it by USB, and accept its **Trust This Computer** prompt if shown:

```bash
idevice_id -l
export DEVICE_UDID='YOUR_IPAD_UDID'
idevicepair -u "$DEVICE_UDID" pair
idevicepair -u "$DEVICE_UDID" validate
ideviceinfo -u "$DEVICE_UDID" -k ProductType
ideviceinfo -u "$DEVICE_UDID" -k ProductVersion
ideviceinfo -u "$DEVICE_UDID" -k CPUArchitecture
```

If `pair` asks you to accept a trust dialog, tap **Trust** on the unlocked iPad, enter its passcode if requested, then rerun `pair` and `validate`. With several USB devices attached, identify the intended iPad and always pass its `-u` argument; do not blindly use the first identifier.

For launch debugging and screenshots, mount an Apple-signed developer disk image compatible with the iPad's OS. Modern Xcode may also need this before it can prepare an old device for provisioning. For the tested iOS 9.3.5 device:

```bash
ideviceimagemounter -u "$DEVICE_UDID" mount \
  /path/to/9.3/DeveloperDiskImage.dmg \
  /path/to/9.3/DeveloperDiskImage.dmg.signature
```

The image used for this test was the iOS 9.3 image mirrored by [iGhibli/iOS-DeviceSupport](https://github.com/iGhibli/iOS-DeviceSupport/tree/master/DeviceSupport), which the device accepted. The image is not included here.

The connected iPad mini 2 on iOS 12.5.8 accepted that mirror's **12.4 (16G73)** image. For this specific OS/device, the equivalent command is:

```bash
ideviceimagemounter -u "$DEVICE_UDID" mount \
  '/path/to/12.4 (16G73)/DeveloperDiskImage.dmg' \
  '/path/to/12.4 (16G73)/DeveloperDiskImage.dmg.signature'
```

Do not use the iOS 9.3 image on the mini 2. An image mount supports debugging; it does not downgrade or replace the device's OS.

If you already have a matching development profile, skip the provisioning command below. Otherwise add the development account in **Xcode → Settings → Accounts**, select its existing team, and run:

```bash
export DEVELOPMENT_TEAM='YOUR_TEAM_ID'
bash scripts/provision.sh
```

This invokes Xcode's automatic device registration/provisioning against Apple's developer service, using the `BUILD_ARCH` selected above (default: `armv7`). A new app identifier/profile may be created. The Xcode build subsequently rejects armv7; that rejection is expected for Route A. The script succeeds only if it finds an unexpired development profile authorizing the device, team and bundle identifier. Its log stays in `.private/provision.log`. Use the output of your selected build script for signing; the Xcode project is a provisioning helper.

Use your own bundle identifier if required by your account, updating `app/Info.plist`, `project.yml`, `scripts/provision.sh` and the expected identifier in `scripts/check-app.py` together.

## 5. Sign and install

Set `PROFILE` to the development profile reported by the provisioning step:

```bash
export PROFILE='/path/to/development.mobileprovision'
python3 scripts/sign.py "$PROFILE" --udid "$DEVICE_UDID" --app "$APP_PATH"
ideviceinstaller -u "$DEVICE_UDID" install "${APP_PATH%.app}.ipa"
```

Wait for `Install: Complete`. Then open **Legacy Display** directly on the iPad. If iOS shows an untrusted developer message, follow the trust option for your own developer identity under **Settings → General → Profiles & Device Management** (the label may vary by OS). Keep the iPad unlocked and the app in the foreground.

Optional terminal launch, after mounting the compatible developer disk image:

```bash
idevicedebug -u "$DEVICE_UDID" --detach run com.sheneyan.oldipad.display
```

Launch debugging can return `Locked` even when installation succeeded. Unlock the device and open the app manually.

The signer verifies the profile's device/app authorization, expiration, development entitlement and matching local identity. Private keys remain in Keychain. Signed packages, provisioning profiles and device identifiers must not be published. The generated IPA is device/profile-specific, not a general downloadable release.

## 6. Connect and use the extra desktop

1. Keep the Mac unlocked, the USB cable connected and **Legacy Display** open on the iPad in landscape orientation. A black screen before connection is normal: Build 5 hides the diagnostics overlay.
2. On the Mac, open **OpenDisplay**, select **Extend**, and click **Connect** next to the correct USB iPad.
3. Open **System Settings → Displays → Arrange** (or OpenDisplay's **Arrange Displays…**) and position the iPad display to match your desk.
4. Drag a window or move the pointer beyond that edge of your Mac desktop. An empty wallpaper on the iPad means an extended desktop is active; move a window onto it to see content.
5. Use the Mac keyboard and mouse. Touch input on the iPad is not implemented.

The armv7 logical desktop is **1280 × 960**, scaled into a **1024 × 768** video stream. The arm64 build offers independent desktop and video settings (see below). The sender may display `1024×768` in its connection status even though macOS reports a 1280 × 960 desktop. Small text can look soft after scaling. The original Build 5 configuration did not use a Retina iPad's full panel resolution.

To reconnect later, plug in USB, unlock the iPad, open Legacy Display, then click **Connect** in OpenDisplay if needed. Leaving the receiver app or locking the iPad stops its receiver. To disconnect intentionally, use **Disconnect** in OpenDisplay. Renew the development profile and re-sign/reinstall when it expires. Installing on another iPad requires a profile authorizing that device, even if the app's architecture matches.

## iPad mini 2 resolution settings (arm64 Build 7 and later)

**Hold anywhere on the iPad image for one second** to open **Display Settings**. This also works when no desktop image is arriving. The page lists both groups of resolutions; a checkmark identifies the saved selection in each group. Tap a resolution row directly, scroll down for Video Quality, and tap **Done** to return to the display.

- **Desktop Size**: 1024 × 768, 1280 × 960, 1440 × 1080, 1600 × 1200, 1920 × 1440, 2048 × 1536, 2560 × 1920, 3072 × 2304, or 4096 × 3072.
- **Video Quality**: 1024 × 768, 1280 × 960, 1440 × 1080, 1600 × 1200, 1920 × 1440, or 2048 × 1536.
- Selecting a value saves it on the iPad and reconnects that receiver. Click **Connect** in the Mac sender if automatic reconnection does not resume. The iPad 2 armv7 build keeps its existing fixed settings.

The [mini 2 panel](https://support.apple.com/en-ie/112019) has 2048 × 1536 physical pixels. Larger desktop sizes fit more content by making it smaller; they cannot add physical pixels. The video setting controls the transport ceiling, separately from desktop space. OpenDisplay's Quality option can reduce the actual stream below that ceiling. For tests at the requested ceiling, select **Best (native)** on the Mac.

Sizes above 2048 × 1536 are marked experimental. Even smaller options can be rejected by macOS virtual-display creation or the receiver's decoder. The first 2048 × 1536 desktop attempt did not become an online Mac virtual display, before a new video stream started. The Mac was subsequently found locked, so that attempt does not establish a resolution or decoder limit. If a selected desktop fails, hold the iPad image and return **Desktop Size** to **1280 × 960**. If video fails, lower **Video Quality** to **1024 × 768**. No Mac restart is required to access the receiver's menu.

Build 7 was verified on the mini 2 through the actual settings page: a long press opened the list, tapping **1600 × 1200** selected the row, and the receiver reconnected. macOS reported an online, unmirrored **1600 × 1200** desktop; sender logs confirmed a **2048 × 1536** H.264 stream. A device screenshot showed the test text, color blocks and animated counter after the change. The remaining desktop presets have not all been tested on hardware.

The arm64 desktop default remains 1280 × 960; the video default is 2048 × 1536. Every listed choice remains selectable. Display-mode creation, decoding and sustained performance must be distinguished; offering a choice does not certify that mode on every Mac/OS combination.

## Troubleshooting

| Symptom | What to check |
| --- | --- |
| `idevice_id -l` is empty | Unlock the device, use a USB data cable, and try a direct port. |
| `Invalid HostID`, not paired, or pending trust | Run `idevicepair ... pair`, accept Trust on the iPad, then validate again. |
| `Could not locate Developer Disk Image` | Mount a compatible Apple-signed image, then retry preparation/debug launch. This is separate from the app SDK. |
| Xcode says armv7 is unsupported | Expected after the provisioning helper has created a matching profile. Use `build.sh` for armv7 or `build-arm64.sh` for arm64; confirm `provision.sh` actually found a profile. |
| No matching profile or local identity | Check the selected team/account, certificate in Keychain, profile expiry, bundle ID and target device authorization. See `.private/provision.log` locally. |
| Installation rejected on iOS 11+ | Use the arm64 output, not the 32-bit IPA. The supplied arm64 route requires iOS 12+. |
| OpenDisplay says to open the app | Launch **Legacy Display** on the iPad and leave it foreground, then retry Connect. |
| Black screen after connecting | Unlock the Mac; confirm Screen Recording permission, Extend mode, and the correct USB device. Retry Disconnect/Connect with the receiver open. |
| Wallpaper but no windows | The new desktop is empty. Check its arrangement and drag a window onto it. |
| App worked before but no longer launches | Check development profile/certificate validity; obtain a valid profile, re-sign and reinstall. |

For a bug report, include the iPad model identifier, iOS version, Mac/Xcode/OpenDisplay versions, selected build architecture, and a redacted error message. Omit UDIDs, profiles, signed IPAs, credentials and screenshots containing personal information.

## Updating an installed receiver

Run `git pull --ff-only`, repeat the selected architecture's build commands, and repeat step 5 with a valid profile for the intended device. Keep `APP_PATH`, `BUILD_ARCH` and `DEVICE_UDID` matched to that device. Open the app and reconnect afterward. You do not need to uninstall it first. The armv7 and arm64 packages are separate outputs; do not exchange them.

## Repeat the visual check

With the receiver connected:

```bash
xcrun swiftc scripts/display-smoke.swift -o build/display-smoke
build/display-smoke
```

This opens its own temporary test window on the main screen, moves it to the OpenDisplay screen after two seconds, displays text/color/animation, then exits after 45 seconds. It does not move existing user windows. If multiple OpenDisplay receivers are connected, it selects the first matching screen; use only the intended receiver for this check.

Device screenshots can be collected locally with `idevicescreenshot`. Their stored pixel orientation may differ from the physical landscape orientation. All local evidence belongs under ignored `build/evidence/`.

## Source layout

| Path | Responsibility |
| --- | --- |
| `app/main.m` | UIKit lifecycle, foreground receiver and hidden diagnostics label |
| `app/ODDisplaySettings.m` | Independent desktop/video presets and legacy hello dimensions |
| `app/ODReceiver.m` | USB TCP listener, framing, pv3 hello, heartbeat and reconnect state |
| `app/ODVideoView.m` | H.264 parameter sets, owned CoreMedia buffers, display layer and cursor |
| `app/ODProtocol.c` | Bounded frame assembly, control demux and Annex B traversal |
| `scripts/` | Local SDK preparation, build, provisioning, signing and verification |
| `tests/` | Fragmentation, coalescing, bounds and NAL parsing tests |

See [HANDOFF.md](HANDOFF.md) for the tested state and remaining limits, and [THIRD_PARTY.md](THIRD_PARTY.md) for external components.

## License

The original receiver source and documentation in this repository are licensed under [MIT](LICENSE). External SDKs, Apple frameworks, tools and OpenDisplay itself retain their own licenses. This project does not change the license of OpenDisplay or redistribute its sender source.
