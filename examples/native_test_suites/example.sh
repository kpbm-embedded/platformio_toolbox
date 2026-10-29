#!/usr/bin/env bash
# about: 3 Unity suites (10 cases) on native, -f filter, test_build_src, test_ignore; BlackPill test firmware built without a board
# Usage (through ./pio-box examples ...): example.sh build | test | run
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
case "${1:-run}" in
  build) ex_build native blackpill ;;
  test)
    ex_build native blackpill
    ex_check native blackpill
    ex_utest -e native
    grep -q '10 test cases: 10 succeeded' <<<"$TEST_OUTPUT" || { echo "FAIL: expected 10 passing cases"; exit 1; }
    ex_utest -e native -f test_pid
    grep -q '4 test cases: 4 succeeded' <<<"$TEST_OUTPUT" || { echo "FAIL: -f test_pid should run 4 cases"; exit 1; }
    # embedded: build (not upload, not run) the test firmware of every suite not ignored for the board
    ex_utest -e blackpill --without-uploading --without-testing
    # --without-testing reports each built suite as SKIPPED; a compile error would be ERRORED
    for suite in test_pid test_debounce; do
      grep -q "blackpill:$suite \[SKIPPED\]" <<<"$TEST_OUTPUT" || { echo "$TEST_OUTPUT" | tail -20; echo "FAIL $suite not built for blackpill"; exit 1; }
    done
    if grep -qE 'ERRORED|Processing test_app in blackpill' <<<"$TEST_OUTPUT"; then echo "FAIL blackpill test build (error or test_app not ignored)"; exit 1; fi
    echo "ok    blackpill: test firmware of 2 suites built (test_app ignored)"
    echo "PASS native_test_suites (10 host cases, filter, embedded test build)" ;;
  run) ex_utest -e native ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
