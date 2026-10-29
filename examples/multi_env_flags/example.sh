#!/usr/bin/env bash
# about: one source, 5 envs (BlackPill, WeAct G431/H743, ESP32-C3, native): [common] + extends, per-env -D flags, build_src_filter
# Usage (through ./pio-box examples ...): example.sh build | test | run
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ENVS=(blackpill weact_g431 weact_h743 esp32c3 native)
has_text() { # file text: the string is in the binary
  if grep -aq -- "$2" "$1"; then echo "ok    $(basename "$(dirname "$1")"): \"$2\""; else echo "FAIL  $1 lacks \"$2\""; return 1; fi
}
case "${1:-run}" in
  build) ex_build "${ENVS[@]}" ;;
  test)
    ex_build "${ENVS[@]}"
    ex_check "${ENVS[@]}"
    has_text "$(firmware blackpill)" "board=blackpill_f411 family=stm32"
    has_text "$(firmware weact_g431)" "board=weact_g431 family=stm32"
    has_text "$(firmware weact_g431)" "fdcan=available"
    has_text "$(firmware weact_h743)" "board=weact_h743 family=stm32"
    has_text "$(firmware esp32c3)" "board=esp32c3 family=esp32"
    if grep -aq "fdcan=available" "$(firmware blackpill)"; then echo "FAIL  build_src_filter leaked into blackpill"; exit 1; fi
    [[ "$("$(firmware native)")" == "board=native family=host fw=multi_env_flags" ]] || { echo "FAIL native output"; exit 1; }
    echo "PASS multi_env_flags (${#ENVS[@]} envs, per-env flags verified in the binaries)" ;;
  run) ex_build native; "$(firmware native)"; ex_run ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
