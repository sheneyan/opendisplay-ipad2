#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$ROOT/build/tests"
xcrun clang -Wall -Wextra -Werror -fsanitize=address,undefined -I"$ROOT/app" \
  "$ROOT/tests/protocol_tests.c" "$ROOT/app/ODProtocol.c" -o "$ROOT/build/tests/protocol_tests"
"$ROOT/build/tests/protocol_tests"
xcrun clang -Wall -Wextra -Werror -Wno-unused-parameter -fobjc-arc -fblocks \
  -fsanitize=address,undefined -I"$ROOT/app" "$ROOT/tests/listener_lifecycle_test.m" \
  "$ROOT/app/ODReceiver.m" "$ROOT/app/ODProtocol.c" -framework Foundation \
  -o "$ROOT/build/tests/listener_lifecycle_test"
"$ROOT/build/tests/listener_lifecycle_test"
