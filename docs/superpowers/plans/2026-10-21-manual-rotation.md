# Manual Rotation Implementation Plan

**Goal:** Replace gravity rotation with a persistent Rotate 90° menu on both iPads.
**Architecture:** A fixed landscape UIKit root contains a rotated canvas shared by video, touch and an embedded settings controller. Saved quarter turns select canvas bounds and receiver portrait fields.
**Tech stack:** Objective-C, UIKit iOS 9/12, Foundation test harness, existing USB transport.

- [x] Add `tests/rotation_settings_test.m`: default landscape, four-step wrap, persisted reread, invalid stored preference, and unchanged desktop/video choices. Run standalone Foundation test and observe missing symbols fail.
- [x] Implement `ODRotationQuarterTurns` and `ODRotateClockwise` in `app/ODDisplaySettings.{h,m}`; include the test in `scripts/test.sh`.
- [x] In `app/main.m`, create transformed content canvas, restrict system rotation, add embedded settings with Rotate on both targets, restore selection before receiver startup. In `app/ODTouchView.m`, enable stationary hold on both targets. Set Build 11 and landscape-only plist.
- [x] Run full tests and both build scripts, check armv7 metadata and diff. Sign/install on exact authorized devices while retaining rollback packages.
- [ ] Verify user path: hold → Rotate → full-frame result, physical movement does not change it, four directions, touch/settings behavior and relaunch persistence. Record actual reconnection delays without claiming improvement from the control change alone.
- [ ] Rewrite README/capabilities and HANDOFF for final manual behavior; commit/push only after review and bounded validation.
