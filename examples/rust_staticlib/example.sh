#!/usr/bin/env bash
# about: Rust no_std staticlib (cargo via 32_17_embedded_rust) linked into C++: cargo test + 3 Unity tests on native, BlackPill + Pico firmware
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
RUST_BOX=$(sibling_launcher BOX_EMBEDDED_RUST 32_17_embedded_rust rust-box) || exit 3
ENVS=(native blackpill pico)
case "${1:-run}" in
  build) ex_build "${ENVS[@]}" ;;
  test)
    out=$("$RUST_BOX" cargo test --lib --quiet --manifest-path "$EX_DIR/rust/Cargo.toml" --target-dir "$EX_OUT/cargo-test" 2>&1) \
      || { echo "$out"; echo "FAIL cargo test"; exit 1; }
    grep -q 'test result: ok. 2 passed' <<<"$out" && echo "ok    cargo test on the host: 2 passed" || { echo "$out"; exit 1; }
    ex_build "${ENVS[@]}"
    ex_check "${ENVS[@]}"
    [[ "$("$(firmware native)")" == "fletcher16=0xC8F0" ]] && echo "ok    host program calls Rust" || { echo "FAIL host program"; exit 1; }
    need_symbols "$(tc_bin arm-none-eabi-nm)" "$(elf blackpill)" box_fletcher16 box_ema_update
    need_symbols "$(tc_bin arm-none-eabi-nm)" "$(elf pico)" box_fletcher16 box_ema_update
    ex_utest -e native
    grep -q '3 test cases: 3 succeeded' <<<"$TEST_OUTPUT" || { echo "FAIL: expected 3 passing Unity cases"; exit 1; }
    echo "PASS rust_staticlib (cargo test 2, Unity 3, 2 firmware builds with Rust inside)" ;;
  run) ex_build native; "$(firmware native)" ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
