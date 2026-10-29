#!/usr/bin/env bash
# about: library package (library.json): 5 Unity tests on native, pio ci builds examples/ for nano + pico, pio pkg pack tarball checked
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ci_build() { # pio ci: the library example built against the library for the nano and pico envs
  "$BOX" run pio ci "$EX_DIR/examples/checksum" --lib "$EX_DIR" --project-conf "$EX_DIR/platformio.ini" \
    -e nano -e pico --build-dir "$EX_OUT/ci" --keep-build-dir
}
case "${1:-run}" in
  build) ci_build ;;
  test)
    ex_utest -e native
    grep -q '5 test cases: 5 succeeded' <<<"$TEST_OUTPUT" || { echo "FAIL: expected 5 passing tests"; exit 1; }
    ci_out=$(ci_build 2>&1) || { echo "$ci_out"; echo "FAIL pio ci"; exit 1; }
    for env in nano pico; do
      grep -qE "^$env +SUCCESS" <<<"$ci_out" && echo "ok    pio ci: examples/checksum for $env" || { echo "$ci_out" | tail -20; echo "FAIL pio ci $env"; exit 1; }
    done
    mkdir -p "$EX_OUT/pack"
    "$BOX" run pio pkg pack "$EX_DIR" -o "$EX_OUT/pack/" >/dev/null
    tarball="$EX_OUT/pack/box-crc-1.0.0.tar.gz"
    listing=$(tar -tzf "$tarball")
    for wanted in library.json src/box_crc.c src/box_crc.h examples/checksum/checksum.ino; do
      grep -qx "$wanted" <<<"$listing" || { echo "FAIL $wanted not in $tarball"; exit 1; }
    done
    if grep -qE '^(test/|platformio.ini)' <<<"$listing"; then echo "FAIL test/ or platformio.ini packed"; exit 1; fi
    echo "ok    pio pkg pack: $(basename "$tarball") ($(wc -l <<<"$listing") files, test/ excluded)"
    echo "PASS library_package (5 Unity tests, 2 ci builds, package)" ;;
  run) ex_utest -e native ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
