#!/usr/bin/env bash
# about: ring-buffer lib: Unity tests on the host (pio test -e native, env gcc) + same lib built for nano/blackpill
# Usage (through ./pio-box examples ...): example.sh build | test | run
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
case "${1:-run}" in
  build) ex_build native nano blackpill ;;
  test)
    ex_build native nano blackpill
    ex_check native nano blackpill
    [[ "$("$(firmware native)")" == "ringbuf ok" ]] || { echo "FAIL: host program output"; exit 1; }
    test_output=$("$BOX" utest "$EX_DIR" -e native 2>&1) || { echo "$test_output"; echo "FAIL unit tests"; exit 1; }
    tail -8 <<<"$test_output"
    grep -qE '4 test cases: 4 succeeded' <<<"$test_output" || { echo "FAIL: expected 4 passing test cases"; exit 1; }
    echo "PASS unit_test_native (4 Unity tests on the host + 2 firmware builds)" ;;
  run) ex_build native; "$(firmware native)" ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
