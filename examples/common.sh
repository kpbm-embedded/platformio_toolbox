#!/usr/bin/env bash
# Shared by examples/*/example.sh (sourced). Runs inside ./pio-box examples (EX_DIR, BOXT_ROOT,
# BOXT_BUILD set). build = pio run for the given envs (default: the project's default_envs);
# check = each env's firmware file exists; run = print the upload plan (never uploads).
# Depends on ./pio-box build and plan.
set -euo pipefail
shopt -s extglob
BOX="${BOXT_ROOT:?run through ./pio-box examples}/pio-box"
PROJECT=$(basename "${EX_DIR:?}")
WORKSPACE="${BOXT_BUILD:?}/pio/$PROJECT"

firmware() { # env -> the artifact pio writes for it
  case "$1" in
    nano) echo "$WORKSPACE/build/nano/firmware.hex" ;;
    pico) echo "$WORKSPACE/build/pico/firmware.uf2" ;;
    native) echo "$WORKSPACE/build/native/program" ;;
    *) echo "$WORKSPACE/build/$1/firmware.bin" ;;   # esp32s3, blackpill
  esac
}
ex_build() { # [envs...]
  local env env_args=()
  for env in "$@"; do env_args+=(-e "$env"); done
  "$BOX" build "$EX_DIR" "${env_args[@]+"${env_args[@]}"}"
}
ex_check() { # envs...
  local env file failures=0
  for env in "$@"; do
    file=$(firmware "$env")
    if [[ -s "$file" ]]; then echo "ok    $PROJECT/$env: $(basename "$file") $(stat -c %s "$file") bytes"
    else echo "FAIL  $PROJECT/$env: $file missing"; failures=$((failures + 1)); fi
  done
  [[ "$failures" == 0 ]]
}
ex_run() { "$BOX" plan "$EX_DIR"; }
elf() { echo "$WORKSPACE/build/$1/firmware.elf"; }   # env -> ELF (not for native)
tc_bin() { # binutils name (arm-none-eabi-nm, avr-size, ...) -> path in the core dir's toolchains
  local candidate   # unversioned folders first: those are the toolchains the platforms use
  for candidate in "${PLATFORMIO_CORE_DIR:?}"/packages/toolchain-+([!@])/bin/"$1" "$PLATFORMIO_CORE_DIR"/packages/toolchain-*/bin/"$1"; do
    if [[ -x "$candidate" ]]; then echo "$candidate"; return 0; fi
  done
  echo "tc_bin: $1 not found in $PLATFORMIO_CORE_DIR/packages (./pio-box install)" >&2; return 1
}
need_symbols() { # nm-tool elf symbol...: every symbol is defined in the ELF
  local nm=$1 file=$2 symbol missing=0 table
  shift 2
  table=$("$nm" "$file")
  for symbol in "$@"; do
    if grep -qE " [TtDdBbRr] $symbol\$" <<<"$table"; then echo "ok    symbol $symbol in $(basename "$(dirname "$file")")"
    else echo "FAIL  symbol $symbol missing in $file"; missing=$((missing + 1)); fi
  done
  [[ "$missing" == 0 ]]
}
section_addr() { # readelf-tool elf section -> hex address (lowercase, no 0x)
  "$1" -SW "$2" | awk -v s="$3" '{for (i = 1; i <= NF; i++) if ($i == s) {print $(i + 2); exit}}'
}
ex_utest() { # pio test args... -> output in TEST_OUTPUT; fails (printing it) when pio test fails
  TEST_OUTPUT=$("$BOX" utest "$EX_DIR" "$@" 2>&1) || { echo "$TEST_OUTPUT"; echo "FAIL pio test $*"; return 1; }
  grep -E 'test cases|PASSED|FAILED' <<<"$TEST_OUTPUT" | tail -3 || true
}
sibling_launcher() { # VAR id-folder launcher -> path of another Box tool's launcher ($VAR, else the sibling
  # folder of this ID); prints a skip message and returns 3 when it is missing (never installs it here)
  local folder
  for folder in "${!1:-}" "${BOXT_ROOT:?}/../$2"; do
    if [[ -n "$folder" && -x "$folder/$3" ]]; then (cd "$folder" && echo "$PWD/$3"); return 0; fi
  done
  echo "skip: $2 not found (\$$1 or a sibling folder of 32_14_platformio); it provides $3"
  return 3
}
