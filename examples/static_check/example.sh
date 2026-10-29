#!/usr/bin/env bash
# about: pio check (cppcheck + clang-tidy, pinned): clean src/ passes a zero-defect gate; planted bugs in buggy/ are reported
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
case "${1:-run}" in
  build) "$BOX" check "$EX_DIR" -e clean --fail-on-defect low ;;
  test)
    out=$("$BOX" check "$EX_DIR" -e clean -e blackpill --fail-on-defect low 2>&1) || { echo "$out" | tail -30; echo "FAIL clean gate"; exit 1; }
    grep -E '^(clean|blackpill) .*PASSED' <<<"$out" || true
    echo "ok    clean + blackpill: no defects (cppcheck, clang-tidy)"
    if out=$("$BOX" check "$EX_DIR" -e buggy --fail-on-defect high 2>&1); then echo "$out" | tail -30; echo "FAIL buggy/ passed the gate"; exit 1; fi
    for id in arrayIndexOutOfBounds memleak uninitvar clang-analyzer-core.uninitialized.UndefReturn \
        clang-analyzer-unix.Malloc clang-analyzer-core.UndefinedBinaryOperatorResult; do
      grep -q -- "$id" <<<"$out" && echo "ok    buggy: $id reported" || { echo "$out" | tail -40; echo "FAIL $id not reported"; exit 1; }
    done
    echo "PASS static_check (gate passes on clean code; 3 planted bugs found by both tools)" ;;
  run) "$BOX" check "$EX_DIR" -e buggy || true ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
