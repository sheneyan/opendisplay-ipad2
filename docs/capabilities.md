# Capability comparison

Compared on October 21, 2026 against the installed **OpenDisplay 1.19.0** sender, its [README](https://github.com/peetzweg/opendisplay/blob/v1.19.0/README.md) and [pv3 wire specification](https://github.com/peetzweg/opendisplay/blob/v1.19.0/PROTOCOL.md). This client is independently implemented; protocol availability does not imply hardware support or a tested feature.

| Capability | Legacy Display status |
| --- | --- |
| USB extended display, multiple receivers | Implemented; iPad 2 and mini 2 tested together. |
| H.264 decoding, keyframe recovery, TCP cursor sprites | Implemented. |
| Tap, drag, two-finger scroll | Implemented and physically tested in Build 8. |
| Independent desktop/video presets | Implemented on mini 2; iPad 2 uses fixed conservative sizes. |
| Manual four-direction rotation | Build 13: long-press settings → Rotate 90° on both devices, with saved direction. Single-device automated rotation/display checks pass; iPad 2 physical menu/touch acceptance also passed. The user confirmed mini 2 rotation works but is slow; the cause is unresolved and is not established as an M1 limitation. Mini 2 touch after rotation was not separately confirmed. Rotate with only one legacy iPad connected; multi-device recovery is unresolved. See README. |
| Gravity-driven rotation | Disabled in Build 11 after the Build 10 trial failed acceptance. |
| Mirroring and Mac-side quality selection | Provided by the Mac sender; not separate receiver features. Mirroring has not been physically validated here. |
| WiFi/LAN and Bonjour discovery | Missing. Current listener accepts loopback USB connections only. |
| UDP cursor positions | Missing; useful over WiFi. USB cannot transport this optional side channel. Existing TCP cursor rendering remains available. |
| Latency/clock synchronization, performance overlay, receiver stats reports | Missing. Basic heartbeats and local counters exist; diagnostics remain hidden as requested. |
| Visible compatibility/update guidance | Incomplete. Protocol notices only update the hidden status text. |
| Pencil pressure/tilt/hover | Protocol-defined, not implemented. The official README still describes Pencil polish as roadmap work. Neither tested iPad supports Apple Pencil; this is not a useful target for these devices. See [Apple's compatibility list](https://support.apple.com/en-us/108937). |

Audio is out of scope and HEVC is planned in the pinned official README; neither is an already-shipped official feature missing only from this client. Mac-to-Mac reception uses a separate official application. Background streaming is not supported here; keep Legacy Display foregrounded.

The most useful separate follow-up would be WiFi discovery and connection. It would need its own usability and LAN-access review, not just changing the listening address. No WiFi listener or additional telemetry was enabled by the rotation work.
