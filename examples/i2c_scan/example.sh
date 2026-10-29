#!/usr/bin/env bash
# about: Wire scan 0x08..0x77, envs nano/esp32s3/pico/blackpill
# Usage (through ./pio-box examples ...): example.sh build | test | run
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
BOARD_ENVS=(nano esp32s3 pico blackpill)
case "${1:-run}" in
  build) ex_build "${BOARD_ENVS[@]}" ;;
  test) ex_build "${BOARD_ENVS[@]}" && ex_check "${BOARD_ENVS[@]}" && echo "PASS i2c_scan (${#BOARD_ENVS[@]} envs)" ;;
  run) ex_run ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
