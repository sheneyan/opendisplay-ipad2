#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/build/tests"
xcrun clang -Wall -Wextra -Werror -fsanitize=address,undefined -I"$ROOT/app" \
  "$ROOT/tests/protocol_tests.c" "$ROOT/app/ODProtocol.c" -o "$ROOT/build/tests/protocol_tests"
"$ROOT/build/tests/protocol_tests"
xcrun clang -Wall -Wextra -Werror -Wno-unused-parameter -fobjc-arc -fblocks \
  -fsanitize=address,undefined -I"$ROOT/app" "$ROOT/tests/listener_lifecycle_test.m" \
  "$ROOT/app/ODReceiver.m" "$ROOT/app/ODLog.m" "$ROOT/app/ODVideoDelivery.m" "$ROOT/app/ODDisplaySettings.m" "$ROOT/app/ODProtocol.c" -framework Foundation \
  -o "$ROOT/build/tests/listener_lifecycle_test"
"$ROOT/build/tests/listener_lifecycle_test"
xcrun clang -DOD_RETINA_SETTINGS=1 -Wall -Wextra -Werror -Wno-unused-parameter -fobjc-arc -fblocks \
  -fsanitize=address,undefined -I"$ROOT/app" "$ROOT/tests/listener_lifecycle_test.m" \
  "$ROOT/app/ODReceiver.m" "$ROOT/app/ODLog.m" "$ROOT/app/ODVideoDelivery.m" "$ROOT/app/ODDisplaySettings.m" "$ROOT/app/ODProtocol.c" -framework Foundation \
  -o "$ROOT/build/tests/retina_settings_test"
"$ROOT/build/tests/retina_settings_test"

xcrun clang -Wall -Wextra -Werror -Wno-unused-parameter -fobjc-arc -fblocks \
  -fsanitize=address,undefined -I"$ROOT/app" "$ROOT/tests/touch_input_tests.m" \
  "$ROOT/app/ODTouchInput.m" -framework Foundation -o "$ROOT/build/tests/touch_input_tests"
"$ROOT/build/tests/touch_input_tests"

python3 "$ROOT/tests/launcher_tests.py"

xcrun clang -Wall -Wextra -Werror -fobjc-arc -fsanitize=address,undefined -I"$ROOT/app" \
  "$ROOT/tests/rotation_settings_test.m" "$ROOT/app/ODDisplaySettings.m" -framework Foundation \
  -o "$ROOT/build/tests/rotation_settings_test"
"$ROOT/build/tests/rotation_settings_test"

xcrun clang -Wall -Wextra -Werror -Wno-unused-parameter -fobjc-arc -fblocks \
  -fsanitize=address,undefined -I"$ROOT/app" "$ROOT/tests/render_isolation_test.m" \
  "$ROOT/app/ODReceiver.m" "$ROOT/app/ODLog.m" "$ROOT/app/ODVideoDelivery.m" "$ROOT/app/ODDisplaySettings.m" "$ROOT/app/ODProtocol.c" \
  -framework Foundation -o "$ROOT/build/tests/render_isolation_test"
"$ROOT/build/tests/render_isolation_test"

xcrun clang -Wall -Wextra -Werror -Wno-unused-parameter -fobjc-arc -fblocks \
  -fsanitize=address,undefined -I"$ROOT/app" "$ROOT/tests/video_delivery_tests.m" \
  "$ROOT/app/ODVideoDelivery.m" -framework Foundation -o "$ROOT/build/tests/video_delivery_tests"
"$ROOT/build/tests/video_delivery_tests"

xcrun clang -Wall -Wextra -Werror -fobjc-arc -fblocks -fsanitize=address,undefined -I"$ROOT/app" \
  "$ROOT/tests/log_isolation_tests.m" "$ROOT/app/ODLog.m" -framework Foundation -o "$ROOT/build/tests/log_isolation_tests"
"$ROOT/build/tests/log_isolation_tests"
