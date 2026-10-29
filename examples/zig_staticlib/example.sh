#!/usr/bin/env bash
# about: Zig staticlib (zig build-lib via 32_24_microzig) linked into C++: zig test + 3 Unity tests on native, BlackPill + ESP32-C3 firmware
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ZIG_BOX=$(sibling_launcher BOX_MICROZIG 32_24_microzig microzig-box) || exit 3
ENVS=(native blackpill esp32c3)
case "${1:-run}" in
  build) ex_build "${ENVS[@]}" ;;
  test)
    out=$("$ZIG_BOX" zig test "$EX_DIR/zig/box_zig.zig" --cache-dir "$EX_OUT/zig-test-cache" 2>&1) || { echo "$out"; echo "FAIL zig test"; exit 1; }
    grep -q 'All 2 tests passed' <<<"$out" && echo "ok    zig test on the host: 2 passed" || { echo "$out"; exit 1; }
    ex_build "${ENVS[@]}"
    ex_check "${ENVS[@]}"
    [[ "$("$(firmware native)")" == "crc16_modbus=0x4B37" ]] && echo "ok    host program calls Zig" || { echo "FAIL host program"; exit 1; }
    need_symbols "$(tc_bin arm-none-eabi-nm)" "$(elf blackpill)" box_crc16_modbus box_adc_to_mv
    need_symbols "$(tc_bin riscv32-esp-elf-nm)" "$(elf esp32c3)" box_crc16_modbus box_adc_to_mv
    ex_utest -e native
    grep -q '3 test cases: 3 succeeded' <<<"$TEST_OUTPUT" || { echo "FAIL: expected 3 passing Unity cases"; exit 1; }
    echo "PASS zig_staticlib (zig test 2, Unity 3, 2 firmware builds with Zig inside)" ;;
  run) ex_build native; "$(firmware native)" ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
