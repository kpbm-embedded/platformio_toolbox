#!/usr/bin/env bash
# about: registry library pinned (ArduinoJson 7.4.3) in a local lib: 5 Unity tests on native + ESP32-C3 and BlackPill builds
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ENVS=(native esp32c3 blackpill)
case "${1:-run}" in
  build) ex_build "${ENVS[@]}" ;;
  test)
    ex_build "${ENVS[@]}"
    ex_check "${ENVS[@]}"
    version=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$WORKSPACE/libdeps/native/ArduinoJson/library.json" | head -1)
    [[ "$version" == 7.4.3 ]] && echo "ok    ArduinoJson $version in the workspace libdeps (pinned)" || { echo "FAIL ArduinoJson version '$version'"; exit 1; }
    [[ "$("$(firmware native)")" == '{"name":"adc0","rate_hz":100,"channels":[0,1,4]}' ]] && echo "ok    host program round trip" || { echo "FAIL host program"; exit 1; }
    ex_utest -e native
    grep -q '5 test cases: 5 succeeded' <<<"$TEST_OUTPUT" || { echo "FAIL: expected 5 passing cases"; exit 1; }
    echo "PASS lib_deps_json (pinned registry lib, 5 tests, 2 firmware builds)" ;;
  run) ex_build native; "$(firmware native)" ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
