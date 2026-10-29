#!/usr/bin/env bash
# about: size gates: post-script flash/RAM budget (pass on nano + blackpill, fail on nano_tight) and board_upload.maximum_size override
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
must_fail() { # env pattern: the build of env fails and prints pattern
  local out
  if out=$("$BOX" build "$EX_DIR" -e "$1" 2>&1); then echo "FAIL $1 built although over budget"; return 1; fi
  grep -q -- "$2" <<<"$out" && echo "ok    $1 fails: $(grep -m1 -- "$2" <<<"$out")" || { tail -15 <<<"$out"; echo "FAIL $1: no '$2'"; return 1; }
}
case "${1:-run}" in
  build) ex_build nano blackpill ;;
  test)
    out=$("$BOX" build "$EX_DIR" -e nano -e blackpill 2>&1) || { tail -20 <<<"$out"; echo "FAIL in-budget builds"; exit 1; }
    grep 'budget.py: flash' <<<"$out" || true   # printed only when the ELF is relinked
    ex_check nano blackpill
    must_fail nano_tight 'OVER BUDGET'
    must_fail nano_small_board 'is greater than maximum allowed'
    size=$("$BOX" build "$EX_DIR" -e nano -t size 2>&1) || { echo "$size"; exit 1; }
    grep -qE '^Program: +[0-9]+ bytes' <<<"$size" && echo "ok    -t size (avr-size): $(grep -E '^Program: ' <<<"$size" | tr -s ' ')" || { echo "FAIL -t size"; exit 1; }
    echo "PASS size_budget (2 in budget, 2 gates fail as intended)" ;;
  run) "$BOX" build "$EX_DIR" -e nano -t size ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
