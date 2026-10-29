#!/usr/bin/env bash
# about: custom board JSON (boards/weact_h562rg.json, WeAct STM32H562 core board, Cortex-M33): build + ELF memory checks
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
case "${1:-run}" in
  build) ex_build weact_h562 ;;
  test)
    ex_build weact_h562
    ex_check weact_h562
    readelf=$(tc_bin arm-none-eabi-readelf)
    file=$(elf weact_h562)
    grep -q 'Tag_CPU_arch: v8-M.mainline' <<<"$("$readelf" -A "$file")" && echo "ok    ELF built for Armv8-M mainline (Cortex-M33)" || { echo "FAIL cpu attribute"; exit 1; }
    vectors=$(section_addr "$readelf" "$file" .isr_vector)
    [[ "$vectors" == 08000000 ]] && echo "ok    .isr_vector at 0x$vectors (flash)" || { echo "FAIL .isr_vector at 0x$vectors"; exit 1; }
    data=$(section_addr "$readelf" "$file" .data)
    [[ "$data" == 200* ]] && echo "ok    .data at 0x$data (SRAM)" || { echo "FAIL .data at 0x$data"; exit 1; }
    need_symbols "$(tc_bin arm-none-eabi-nm)" "$file" setup loop SystemInit
    size=$(stat -c %s "$(firmware weact_h562)")
    (( size < 1048576 )) && echo "ok    $size bytes < 1 MiB (maximum_size from the board JSON)"
    echo "PASS custom_board (weact_h562rg.json)" ;;
  run) ex_run ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
