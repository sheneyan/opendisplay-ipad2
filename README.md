# OpenDisplay iPad 2 Receiver

A small, independent **iOS 9 / armv7 receiver** for the [OpenDisplay protocol](https://github.com/peetzweg/opendisplay/blob/v1.19.0/PROTOCOL.md). It lets an old iPad display an additional Mac desktop over USB, without jailbreaking the iPad.

This is an experimental third-party receiver, not an official OpenDisplay release. The Mac runs the existing OpenDisplay sender; no sender modification was needed for the verified configuration.

## Verified configuration

Tested on October 21, 2026:

| Component | Verified configuration |
| --- | --- |
| Receiver | iPad 2 Wi-Fi (`iPad2,1`), iOS 9.3.5 (13G36), no jailbreak |
| Host | M1 MacBook Air, macOS 26.5 (25F71) |
| Sender | OpenDisplay 1.19.0 |
| Connection | USB / macOS usbmuxd |
| Extended desktop | 1024 × 768 logical points; sender creates a 2048 × 1536 HiDPI backing display |
| Actual video | 1024 × 768 H.264 High Profile, Level 3.2 |
| Display coexistence | Mac internal display + existing 1920 × 1080 physical monitor + independent iPad desktop, all unmirrored |

The app was compiled, development-signed, installed and launched on the real iPad. Device screenshots verified a moved test window, 12/16/24 pt text, color blocks, an animated counter and a cursor. The display layer reported zero errors during these checks. The submitted-frame counter is **not a measurement of physical display FPS or latency**.

Force-quitting and relaunching the receiver, then clicking **Connect** in OpenDisplay on the Mac, restored the extended display. Automatic reconnection after an app exit is not guaranteed by the tested sender. Cable unplug/replug and long-duration use have not been tested.

## Current scope

- USB only; the receiver listens on loopback TCP port 9000, with no Wi-Fi listener.
- Landscape, full-screen video, TCP cursor overlay and a small diagnostics strip.
- H.264 only, with an encoded raster ceiling of 1024 × 768.
- No touch input, audio, Pencil, HEVC, portrait switching or background streaming.
- Keeping the app in the foreground disables auto-lock; leaving the app tears down the receiver.

The receiver advertises a 30 fps capability for newer senders. **OpenDisplay 1.19.0 ignores that capability and still uses its own nominal 60 fps pipeline.** Do not describe this test as a verified 30 or 60 fps presentation result.

The original iPad mini has similar hardware, but has not been tested. No compatibility claim is made for another iPad model or sender version.

## Build prerequisites

- macOS, a full Xcode installation and command-line tools. Tested with Xcode 26.6.
- Xcode's `clang` ARM backend and `ld-classic`. Although Xcode's normal build system rejects armv7, these tools can still build it directly with a legacy SDK.
- An iOS 9.3 SDK obtained under the applicable SDK terms. SDKs and developer disk images are not distributed in this repository.
- Python 3 and PyYAML for preparing the legacy SDK's text stubs.
- An existing Apple development signing identity and a development provisioning profile authorizing both this app and this iPad. Jailbreak or ad-hoc code signing alone is not sufficient.

Install the device tools and project generator:

```bash
brew install libimobiledevice ideviceinstaller xcodegen
git clone https://github.com/sheneyan/opendisplay-ipad2.git
cd opendisplay-ipad2
```

## Prepare the SDK

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

## Build and check

```bash
bash scripts/test.sh
bash scripts/build.sh
python3 scripts/check-app.py
```

`build/LegacyDisplay.app/LegacyDisplay` must be a 32-bit armv7 Mach-O executable with `LC_VERSION_MIN_IPHONEOS` set to iOS 9.0 and SDK 9.3. The build treats compiler warnings as errors. Tests run on the Mac with AddressSanitizer and UndefinedBehaviorSanitizer. The listener regression test exercises the real transport on loopback port 9000 through ten immediate stop/start cycles; keep that host port free while testing.

## Prepare the device and signing profile

Unlock the iPad, connect it by USB, and accept its **Trust This Computer** prompt if shown:

```bash
idevice_id -l
export DEVICE_UDID='YOUR_IPAD_UDID'
idevicepair -u "$DEVICE_UDID" validate
```

For launch debugging and screenshots, mount an Apple-signed iOS 9.3 developer disk image obtained from a compatible Xcode installation:

```bash
ideviceimagemounter -u "$DEVICE_UDID" mount \
  /path/to/9.3/DeveloperDiskImage.dmg \
  /path/to/9.3/DeveloperDiskImage.dmg.signature
```

The image used for this test was the iOS 9.3 image mirrored by [iGhibli/iOS-DeviceSupport](https://github.com/iGhibli/iOS-DeviceSupport/tree/master/DeviceSupport), which the device accepted. The image is not included here.

If you already have a matching development profile, skip the provisioning command below. Otherwise add the development account in **Xcode → Settings → Accounts**, select its existing team, and run:

```bash
export DEVELOPMENT_TEAM='YOUR_TEAM_ID'
bash scripts/provision.sh
```

This invokes Xcode's automatic device registration/provisioning against Apple's developer service. A new app identifier/profile may be created. The Xcode build subsequently rejects armv7; that rejection is expected. The script succeeds only if it finds an unexpired development profile authorizing the device, team and bundle identifier. Its log stays in `.private/provision.log`. `build.sh`, not Xcode, builds the actual executable.

Use your own bundle identifier if required by your account, updating `app/Info.plist`, `project.yml`, `scripts/provision.sh` and the expected identifier in `scripts/check-app.py` together.

## Sign, install and run

Set `PROFILE` to the development profile reported by the provisioning step:

```bash
export PROFILE='/path/to/development.mobileprovision'
python3 scripts/sign.py "$PROFILE" --udid "$DEVICE_UDID"
ideviceinstaller -u "$DEVICE_UDID" install build/LegacyDisplay.ipa
idevicedebug -u "$DEVICE_UDID" --detach run com.sheneyan.oldipad.display
```

You can also open **Legacy Display** directly on the iPad. Keep it unlocked and in the foreground. Launch debugging can return `Locked` even when installation succeeded.

On the Mac, open **OpenDisplay**, choose **Extend**, and click **Connect** beside the USB iPad. The receiver should progress from `Listening over USB :9000` to `USB connected`, followed by the H.264 format and counters. Arrange the new independent display in macOS Displays settings.

The signer verifies the profile's device/app authorization, expiration, development entitlement and matching local identity. Private keys remain in Keychain. Signed packages, provisioning profiles and device identifiers must not be published. The generated IPA is device/profile-specific, not a general downloadable release.

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
| `app/main.m` | UIKit lifecycle, foreground receiver and status strip |
| `app/ODReceiver.m` | USB TCP listener, framing, pv3 hello, heartbeat and reconnect state |
| `app/ODVideoView.m` | H.264 parameter sets, owned CoreMedia buffers, display layer and cursor |
| `app/ODProtocol.c` | Bounded frame assembly, control demux and Annex B traversal |
| `scripts/` | Local SDK preparation, build, provisioning, signing and verification |
| `tests/` | Fragmentation, coalescing, bounds and NAL parsing tests |

See [HANDOFF.md](HANDOFF.md) for the tested state and remaining limits, and [THIRD_PARTY.md](THIRD_PARTY.md) for external components.

## License

The original receiver source and documentation in this repository are licensed under [MIT](LICENSE). External SDKs, Apple frameworks, tools and OpenDisplay itself retain their own licenses. This project does not change the license of OpenDisplay or redistribute its sender source.
