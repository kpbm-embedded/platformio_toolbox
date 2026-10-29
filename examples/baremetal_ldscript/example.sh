#!/usr/bin/env bash
# about: bare metal BlackPill (no framework): own startup + linker script, register blink; vector table, sections and map checked
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
case "${1:-run}" in
  build) ex_build blackpill ;;
  test)
    ex_build blackpill
    ex_check blackpill
    readelf=$(tc_bin arm-none-eabi-readelf)
    file=$(elf blackpill)
    [[ "$(section_addr "$readelf" "$file" .isr_vector)" == 08000000 ]] && echo "ok    .isr_vector at 0x08000000" || { echo "FAIL .isr_vector"; exit 1; }
    [[ "$(section_addr "$readelf" "$file" .data)" == 20000000 ]] && echo "ok    .data at 0x20000000, loaded from flash" || { echo "FAIL .data"; exit 1; }
    need_symbols "$(tc_bin arm-none-eabi-nm)" "$file" Reset_Handler SysTick_Handler main blink_period_ms
    # word 0 of the image = initial stack pointer (end of RAM), word 1 = Reset_Handler | 1 (Thumb)
    read -r sp reset < <(od -An -tx4 -N8 "$(firmware blackpill)")
    [[ "$sp" == 20020000 ]] && echo "ok    initial SP 0x$sp" || { echo "FAIL initial SP 0x$sp"; exit 1; }
    want=$("$(tc_bin arm-none-eabi-nm)" "$file" | awk '$3=="Reset_Handler"{print $1}')
    [[ $((16#$reset)) == $((16#$want | 1)) ]] && echo "ok    reset vector 0x$reset = Reset_Handler|1" || { echo "FAIL reset vector $reset vs $want"; exit 1; }
    size=$(stat -c %s "$(firmware blackpill)")
    (( size < 1024 )) && echo "ok    image $size bytes (< 1 KiB, no framework)" || { echo "FAIL image $size bytes"; exit 1; }
    [[ -s "$WORKSPACE/build/blackpill/firmware.map" ]] && echo "ok    firmware.map written" || { echo "FAIL map"; exit 1; }
    echo "PASS baremetal_ldscript" ;;
  run) ex_run ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
