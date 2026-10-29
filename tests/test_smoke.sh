#!/usr/bin/env bash
# Smoke test of the installed pio-box: pio runs from the pixi env with the core dir inside the ID,
# telemetry is off, all pinned platforms and tools are installed, every template is instantiated
# with `new` and builds / passes its tests / check (no board needed), `plan` only prints,
# ~/.platformio stays untouched.
# Usage: tests/test_smoke.sh   Depends on: tests/testlib.sh, ./pio-box install done.
TEST_LAUNCHER_NAME=pio-box
# shellcheck source-path=SCRIPTDIR source=testlib.sh
. "$(dirname "$0")/testlib.sh"
Q=$LAUNCHER
make_temp_dir
home_entries_before=$(find "$HOME/.platformio" 2>/dev/null | wc -l)

if version=$("$Q" pio --version 2>&1) && grep -q 'PlatformIO Core' <<<"$version"; then ok "$version"; else bad "pio: $version"; fi
# shellcheck disable=SC2016  # $PLATFORMIO_CORE_DIR is expanded by the inner shell
if core_dir=$("$Q" run bash -c 'printf %s "$PLATFORMIO_CORE_DIR"') && [[ "$core_dir" == "$HERE/install/platformio" ]]; then ok "core dir inside the ID"
else bad "core dir: $core_dir"; fi
if "$Q" pio settings get enable_telemetry 2>/dev/null | grep -E 'enable_telemetry +No' >/dev/null; then ok "telemetry off"; else bad "telemetry"; fi
while IFS=$'\t' read -r platform version _; do
  if grep -q "\"version\": \"$version\"" "$HERE/install/platformio/platforms/$platform/platform.json" 2>/dev/null; then ok "platform $platform $version"
  else bad "platform $platform $version"; fi
done < <(grep -v '^#' "$HERE/config/platforms.tsv")
while IFS=$'\t' read -r tool version _; do
  if grep -q "\"version\": \"$version\"" "$HERE/install/platformio/packages/$tool/package.json" 2>/dev/null; then ok "tool $tool $version"
  else bad "tool $tool $version"; fi
done < <(grep -v '^#' "$HERE/config/tools.tsv")
project=smoke_proj
if "$Q" new project "$project" --dir "$TEST_TMP" >/dev/null 2>&1; then
  if output=$("$Q" build "$TEST_TMP/$project" -e nano 2>&1) && grep -q 'SUCCESS' <<<"$output"; then ok "template builds for nano"
  else bad "template nano: $(tail -3 <<<"$output")"; fi
  if output=$("$Q" utest "$TEST_TMP/$project" -e native 2>&1) && grep -q '1 succeeded' <<<"$output"; then ok "template Unity test on the host"
  else bad "template utest: $(tail -3 <<<"$output")"; fi
  if [[ ! -e "$TEST_TMP/$project/.pio" ]]; then ok "no .pio in the project (workspace on \$OUT)"; else bad ".pio created in the project"; fi
else bad "new project"; fi
if output=$("$Q" plan "$TEST_TMP/$project" 2>&1) && grep -q 'PRINTED ONLY' <<<"$output"; then ok "plan prints only"; else bad "plan"; fi
# every other template: `new` + the command its README gives (output patterns from the pio summaries)
template_check() { # kind expected-regex pio-box-args... (the project dir is appended after the command word)
  local kind=$1 pattern=$2 command=$3 dir="$TEST_TMP/t_$1"
  shift 3
  if ! "$Q" new "$kind" "t_$kind" --dir "$TEST_TMP" >/dev/null 2>&1; then bad "new $kind"; return; fi
  check "template $kind: $command $*" "$pattern" "$Q" "$command" "$dir" "$@"
}
template_check multi_board     '8 succeeded'               build
template_check custom_board    '\[SUCCESS\]'               build
template_check extra_scripts   '"elf_sha256"'              build -e blackpill -t fwinfo
template_check static_check    'clean +clangtidy +PASSED'  check -e clean --fail-on-defect low
template_check size_budget     '2 succeeded'               build -e nano -e blackpill
template_check esp32_freertos  '2 succeeded'               build
template_check unit_suites     '10 test cases: 10 succeeded' utest -e native
template_check lib_deps        '5 test cases: 5 succeeded' utest -e native
template_check library         '5 test cases: 5 succeeded' utest -e native
template_check baremetal_stm32 '\[SUCCESS\]'               build
template_check esp32_fs        '\[SUCCESS\]'               build -e esp32s3
check "template esp32_fs: buildfs" 'littlefs.bin|Building FS image' "$Q" build "$TEST_TMP/t_esp32_fs" -e esp32s3 -t buildfs
template_check compiledb       'compile_commands.json'     build -e blackpill -t compiledb
if find "$TEST_TMP" -name .pio -o -name compile_commands.json | grep -q .; then bad ".pio or compile_commands.json inside a template copy"
else ok "templates: no .pio / compile_commands.json in the project folders"; fi
home_entries_after=$(find "$HOME/.platformio" 2>/dev/null | wc -l)
if [[ "$home_entries_after" == "$home_entries_before" ]]; then ok "nothing new in \$HOME/.platformio"; else bad "\$HOME/.platformio changed"; fi
finish smoke
