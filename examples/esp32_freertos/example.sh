#!/usr/bin/env bash
# about: FreeRTOS on ESP32-S3 (tasks pinned to 2 cores) and ESP32-C3 (single core): queue, mutex, event group; ELF symbols checked
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ENVS=(esp32s3 esp32c3)
case "${1:-run}" in
  build) ex_build "${ENVS[@]}" ;;
  test)
    ex_build "${ENVS[@]}"
    ex_check "${ENVS[@]}"
    need_symbols "$(tc_bin xtensa-esp32s3-elf-nm)" "$(elf esp32s3)" sensor_task logger_task xQueueGenericSend xEventGroupSetBits
    need_symbols "$(tc_bin riscv32-esp-elf-nm)" "$(elf esp32c3)" sensor_task logger_task xQueueGenericSend xEventGroupSetBits
    for env in "${ENVS[@]}"; do   # the ESP image header starts with magic byte 0xE9
      [[ "$(head -c1 "$(firmware "$env")" | od -An -tx1 | tr -d ' ')" == e9 ]] && echo "ok    $env: ESP image magic 0xE9" || { echo "FAIL $env image magic"; exit 1; }
    done
    echo "PASS esp32_freertos (2 targets: Xtensa dual core + RISC-V single core)" ;;
  run) ex_run ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
