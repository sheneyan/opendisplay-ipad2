# Legacy receiver touch input implementation plan

**Goal:** Add tap, single-finger drag and two-finger scrolling on iPad 2 and mini 2, retaining the mini's one-second settings hold.

**Architecture:** A Foundation-only gesture state machine emits documented pv3 control messages. A UIKit overlay converts real touch snapshots and schedules the settings hold. The receiver serializes input with video/control traffic and rejects input from an expired connection session. Implement independently from the published wire contract; keep the MIT client license.

**Accepted interaction:** Tap commits on release. Moving a single finger at least eight view points begins a drag at the initial point. A second finger cancels any drag and begins natural scrolling; remaining fingers must lift before a new click. A stationary one-second mini hold opens settings without a Mac click. Cancellation, backgrounding, settings and stream/session changes release any mouse button and invalidate the gesture. Map coordinates against the actual aspect-fit video area; scroll units are decoded video pixels.

- [x] Add failing gesture tests for tap, drag, scrolling, letterbox mapping, long-press suppression and cancellation.
- [x] Implement the state machine and UIKit bridge in separate files; expose decoded video geometry.
- [x] Add session-bound transport input and real TCP tests for messages, cancellation and stale-session rejection.
- [x] Build both architectures and retain the previous signed packages for rollback.
- [x] Install on each attached authorized device; check live display and ask the user to exercise physical taps, drags, two-finger scroll and mini settings using a dedicated test window.
- [x] Update English usage/limitations with actual evidence and publish the scoped change.

Validation commands: `bash scripts/test.sh`, `bash scripts/build.sh`, `python3 scripts/check-app.py`, `bash scripts/build-arm64.sh`, device-specific signing/install commands from the existing README. Do not substitute a successful compile or injected socket message for a physical touch test.
