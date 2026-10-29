#!/usr/bin/env bash
# pio-box tool part: hooks and commands for lib/boxtool.bash (sourced below), run by the
# ./pio-box launcher (never directly). PlatformIO Core from PyPI (pinned in pixi.toml, locked in
# pixi.lock) with PLATFORMIO_CORE_DIR=install/platformio, pinned dev platforms
# (config/platforms.tsv, the same versions as each example's platformio.ini) and every project's
# .pio workspace (build dirs, libdeps) on $OUT/build/pio/<project> (idisk03).
# Depends on: lib/boxtool.bash, the pixi env (pio, gcc), coreutils, awk, sed.
# SAFETY: nothing here uploads to, erases or monitors a board on its own. `list` only enumerates
# ports; `plan` only prints upload commands. `pio` passes whatever *you* type.
set -euo pipefail

# shellcheck disable=SC2034  # TOOL_* are read by lib/boxtool.bash (cmd_help, cmd_install)
{
  TOOL_TITLE="32_14_platformio: PlatformIO Core $(sed -n 's/^platformio = "==\(.*\)"/\1/p' "${BOXT_ROOT:?run through ./pio-box}/pixi.toml" | head -1) with atmelavr, espressif32, raspberrypi, ststm32, native"
  TOOL_INSTALL_WHAT="the pinned platforms + example toolchains (config/platforms.tsv) + native wrappers"
  TOOL_HELP_USE="  platforms [--sizes]     pinned platforms vs installed (--sizes: every package's size)
  build <project-dir> [-e env] [args]   pio run in a project (workspace on \$OUT/build/pio/<name>)
  utest <project-dir> [-e env] [args]   pio test (e.g. -e native: Unity tests on the host gcc)
  check <project-dir> [-e env] [args]   pio check (cppcheck / clang-tidy, pinned in config/tools.tsv)
  list                    read-only: serial ports (pio device list)
  plan <project-dir> [-e env]   PRINT the upload commands (runs nothing)
  pio [args]              pio with this folder's core dir (pass-through)"
}
# shellcheck source-path=SCRIPTDIR source=boxtool.bash
. "$BOXT_ROOT/lib/boxtool.bash"

# Shared machine: these compilers run at most 4 jobs (boxtool allows 8); BOXT_JOBS can lower it.
if [[ "$JOBS" -gt 4 ]]; then JOBS=4; fi

CORE_DIR="$INST/platformio"
PLATFORMS_TSV="$CONFIG/platforms.tsv"
TOOLS_TSV="$CONFIG/tools.tsv"
PIO_CACHE_DIR="$ROOT/cache/platformio"

hook_env() {
  # Everything PlatformIO writes goes here (core dir, http/download cache) or to $OUT (workspaces).
  export PLATFORMIO_CORE_DIR="$CORE_DIR" PLATFORMIO_CACHE_DIR="$PIO_CACHE_DIR" \
         PLATFORMIO_SETTING_ENABLE_TELEMETRY=no PLATFORMIO_SETTING_CHECK_PLATFORMIO_INTERVAL=3650 \
         PLATFORMIO_SETTING_CHECK_PRUNE_SYSTEM_THRESHOLD=0 PLATFORMIO_DISABLE_PROGRESSBAR=true \
         PLATFORMIO_SETTING_ENABLE_PROXY_STRICT_SSL=yes
  export PIP_CACHE_DIR="$ROOT/cache/pip" PIP_DISABLE_PIP_VERSION_CHECK=1
  export XDG_CACHE_HOME="$ROOT/cache/xdg-cache" XDG_CONFIG_HOME="$ROOT/cache/xdg-config" XDG_DATA_HOME="$ROOT/cache/xdg-data"
  if [[ "$DRY" != 1 ]]; then
    mkdir -p "$CORE_DIR" "$PIO_CACHE_DIR" "$XDG_CACHE_HOME" "$XDG_CONFIG_HOME" "$XDG_DATA_HOME" 2>/dev/null || true
  fi
  export PIO_BOX_ROOT="$ROOT" PIO_BOX_PLATFORMS="$PLATFORMS_TSV"
}

# ---------- platforms ----------
platform_rows() { # non-comment lines of config/platforms.tsv: name version upstream notes
  if [[ -r "$PLATFORMS_TSV" ]]; then awk -F'\t' '!/^#/ && NF>=2' "$PLATFORMS_TSV"; fi
}
tool_rows() { # non-comment lines of config/tools.tsv: name version notes
  if [[ -r "$TOOLS_TSV" ]]; then awk -F'\t' '!/^#/ && NF>=2' "$TOOLS_TSV"; fi
}
tool_installed_version() { # name -> version in install/platformio/packages/<name> (or empty)
  local manifest="$CORE_DIR/packages/$1/package.json"
  if [[ -r "$manifest" ]]; then sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$manifest" | head -1; fi
}
platform_installed_version() { # name -> version in install/platformio/platforms/<name> (or empty)
  local manifest="$CORE_DIR/platforms/$1/platform.json"
  if [[ -r "$manifest" ]]; then sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' "$manifest" | head -1; fi
}

telemetry_off() {
  run pio settings set enable_telemetry no >/dev/null
  run pio settings set check_platformio_interval 3650 >/dev/null
}

# ---------- projects ----------
project_dir() { # project dir or example name -> absolute dir with platformio.ini (exit 1 if none)
  local project=$1
  if [[ ! -r "$project/platformio.ini" && -r "$ROOT/examples/$project/platformio.ini" ]]; then project="$ROOT/examples/$project"; fi
  [[ -r "$project/platformio.ini" ]] || return 1
  (cd "$project" && pwd -P)
}
project_workspace() { printf '%s/pio/%s' "$BUILD" "$(basename "$1")"; }
use_workspace() { # project-dir -> PLATFORMIO_WORKSPACE_DIR on $OUT (build dirs, libdeps, test builds)
  PLATFORMIO_WORKSPACE_DIR=$(project_workspace "$1")
  export PLATFORMIO_WORKSPACE_DIR
  if [[ "$DRY" != 1 ]]; then mkdir -p "$PLATFORMIO_WORKSPACE_DIR"; cachedir_tag "$BUILD"; fi
}
project_envs() { sed -n 's/^\[env:\(.*\)\]/\1/p' "$1/platformio.ini"; }
env_option() { # project-dir env key -> value of `key =` in [env:<env>] (empty if unset)
  awk -v section="[env:$2]" -v key="$3" '
    $0==section {inside=1; next}
    /^\[/ {inside=0}
    inside && $0 ~ "^"key" *=" {sub("^"key" *= *",""); print; exit}' "$1/platformio.ini"
}

hook_bootstrap() { cachedir_tag "$ROOT/cache" "$PIO_CACHE_DIR"; }

hook_install() { # demos-flag (unused: there are no demo downloads)
  activate
  telemetry_off
  local name version example
  while IFS=$'\t' read -r name version _; do
    if [[ "$(platform_installed_version "$name")" == "$version" ]]; then info "platform $name@$version already installed"; continue; fi
    wait_for_ram
    info "platform install $name@$version"
    run timeout "$NET_TIMEOUT" pio pkg install -g -p "platformio/$name@$version"
  done < <(platform_rows)
  # tools PlatformIO fetches on first use (pio check, buildfs), pinned so a fresh clone gets the same ones
  while IFS=$'\t' read -r name version _; do
    if [[ "$(tool_installed_version "$name")" == "$version" ]]; then info "tool $name@$version already installed"; continue; fi
    info "tool install $name@$version"
    run timeout "$NET_TIMEOUT" pio pkg install -g -t "platformio/$name@$version"
  done < <(tool_rows)
  # toolchains/frameworks/libraries the examples need (into the core dir; libdeps into $OUT)
  for example in $(ex_list); do
    [[ -r "$ROOT/examples/$example/platformio.ini" ]] || continue
    info "packages for examples/$example"
    use_workspace "$ROOT/examples/$example"
    run timeout "$NET_TIMEOUT" pio pkg install -d "$ROOT/examples/$example"
  done
  cmd_native
}

hook_status() {
  local name version installed=0
  while IFS=$'\t' read -r name version _; do
    if [[ "$(platform_installed_version "$name")" == "$version" ]]; then installed=$((installed + 1)); fi
  done < <(platform_rows)
  printf '  %-22s %s of %s pinned in install/platformio (%s); ./%s platforms --sizes\n' platforms "$installed" \
    "$(platform_rows | wc -l)" "$(human_size "$CORE_DIR")" "$NAME"
}

doctor_serial_group() { # ok/warn line about access to /dev/ttyUSB*/ttyACM*
  local group
  group=$(stat -c %G /dev/ttyUSB0 /dev/ttyACM0 2>/dev/null | head -1 || true)
  if [[ -z "$group" ]]; then d_ok "no serial board connected (list/plan need none)"
  elif id -nG | tr ' ' '\n' | grep -x "$group" >/dev/null; then d_ok "serial ports: user is in group $group"
  else d_warn "serial ports owned by group $group; you are not in it (README 'udev and groups')"; fi
}

doctor_example_pins() { # every example/template `platform = platformio/<name>@<version>` is in platforms.tsv
  local ini pin mismatches=0 count=0
  for ini in "$ROOT"/examples/*/platformio.ini "$ROOT"/templates/*/platformio.ini; do
    [[ -r "$ini" ]] || continue
    count=$((count + 1))
    while IFS= read -r pin; do
      if ! grep -q "^${pin%%@*}	${pin#*@}" "$PLATFORMS_TSV"; then
        mismatches=$((mismatches + 1)); d_fail "${ini#"$ROOT"/} pins $pin, not in config/platforms.tsv"
      fi
    done < <(sed -n 's#^platform *= *platformio/##p' "$ini" | sort -u)
  done
  if [[ "$mismatches" == 0 ]]; then d_ok "platform pins of $count example/template platformio.ini match config/platforms.tsv"; fi
}

hook_doctor() {
  local value name wanted installed
  if value=$(pio --version 2>/dev/null); then d_ok "$value (pixi env)"; else d_fail "pio missing in the pixi env: ./$NAME bootstrap"; fi
  if [[ "$(command -v pio)" == "$ENV_DIR/bin/pio" ]]; then d_ok "pio from .pixi/envs/default"; else d_warn "pio on PATH is $(command -v pio)"; fi
  value=$(pio system info 2>/dev/null | sed -n 's/^PlatformIO Core Directory *//p' || true)
  if [[ "$value" == "$CORE_DIR" ]]; then d_ok "core dir: install/platformio"; else d_fail "core dir is '$value' (expected $CORE_DIR)"; fi
  value=$(pio settings get enable_telemetry 2>/dev/null | grep -iE 'enable_telemetry' | grep -ioE '\b(yes|no)\b' | head -1 || true)
  if [[ "${value,,}" == no ]]; then d_ok "telemetry off"; else d_fail "telemetry not off: ./$NAME install"; fi
  while IFS=$'\t' read -r name wanted _; do
    installed=$(platform_installed_version "$name")
    if [[ "$installed" == "$wanted" ]]; then d_ok "platform $name $installed"
    elif [[ -n "$installed" ]]; then d_fail "platform $name $installed installed, $wanted pinned: ./$NAME install"
    else d_fail "platform $name $wanted not installed: ./$NAME install"; fi
  done < <(platform_rows)
  while IFS=$'\t' read -r name wanted _; do
    installed=$(tool_installed_version "$name")
    if [[ "$installed" == "$wanted" ]]; then d_ok "tool $name $installed"
    else d_fail "tool $name $wanted not installed (have '${installed}'): ./$NAME install"; fi
  done < <(tool_rows)
  if value=$(gcc --version 2>/dev/null | head -1) && [[ "$(command -v gcc)" == "$ENV_DIR/bin/gcc" ]]; then d_ok "host $value (env, for -e native)"
  else d_fail "env gcc missing (native tests): ./$NAME bootstrap"; fi
  doctor_example_pins
  doctor_serial_group
}

hook_native_bins() {
  echo "pio @pio"
  echo "platformio @pio"
}

# ---------- commands ----------
tool_cmd_platforms() {
  activate
  local name version installed package_dir
  printf '%-14s %-9s %-10s %s\n' platform pinned installed size
  while IFS=$'\t' read -r name version _; do
    installed=$(platform_installed_version "$name")
    printf '%-14s %-9s %-10s %s\n' "$name" "$version" "${installed:--}" "$(human_size "$CORE_DIR/platforms/$name")"
  done < <(platform_rows)
  [[ "${1:-}" == --sizes ]] || return 0
  echo "packages (install/platformio/packages):"
  for package_dir in "$CORE_DIR"/packages/*/; do
    [[ -d "$package_dir" ]] || continue
    printf '  %-8s %s\n' "$(human_size "$package_dir")" "$(basename "$package_dir")"
  done
  printf 'total: core dir %s | cache %s | workspaces %s\n' "$(human_size "$CORE_DIR")" "$(human_size "$PIO_CACHE_DIR")" "$(human_size "$BUILD/pio")"
}

tool_cmd_build() { # project [pio run args]
  [[ -n "${1:-}" ]] || usage_error "usage: ./$NAME build <project-dir|example> [-e env] [pio run args]"
  local project
  project=$(project_dir "$1") || usage_error "no platformio.ini in $1"
  shift
  activate; use_workspace "$project"; wait_for_ram
  run pio run -d "$project" -j "$JOBS" "$@"
}

tool_cmd_utest() { # project [pio test args]
  [[ -n "${1:-}" ]] || usage_error "usage: ./$NAME utest <project-dir|example> [-e env] [pio test args]"
  local project
  project=$(project_dir "$1") || usage_error "no platformio.ini in $1"
  shift
  activate; use_workspace "$project"; wait_for_ram
  run pio test -d "$project" "$@"
}

tool_cmd_check() { # project [pio check args]
  [[ -n "${1:-}" ]] || usage_error "usage: ./$NAME check <project-dir|example> [-e env] [pio check args]"
  local project
  project=$(project_dir "$1") || usage_error "no platformio.ini in $1"
  shift
  activate; use_workspace "$project"; wait_for_ram
  run pio check -d "$project" "$@"
}

tool_cmd_list() {
  activate
  if [[ "$DRY" == 1 ]]; then printf '+ pio device list\n+ lsusb\n'; return 0; fi
  echo "== pio device list (read-only)"
  timeout 60 pio device list 2>&1 || true
  if have lsusb; then
    echo "== lsusb (Arduino/CH340/CP210x/FTDI/Espressif/RP2040/STM32 DFU)"
    lsusb | grep -iE '2341:|2a03:|1a86:|10c4:ea60|0403:6001|303a:|2e8a:|0483:df11' || echo "(none)"
  fi
}

plan_env() { # project-dir env: print the upload commands of one env
  local project=$1 env=$2 workspace board protocol
  workspace=$(project_workspace "$project")
  board=$(env_option "$project" "$env" board)
  protocol=$(env_option "$project" "$env" upload_protocol)
  if [[ "$env" == native ]]; then echo "# env native: host program, nothing to upload ($workspace/build/native/program)"; return 0; fi
  echo "# env $env (board ${board:-?}${protocol:+, upload_protocol $protocol})"
  if [[ ! -d "$workspace/build/$env" ]]; then echo "#   not built yet: ./$NAME build $project -e $env"; fi
  case "$board" in
    nanoatmega328*) echo "./$NAME build $project -e $env -t upload --upload-port /dev/ttyUSB0    # avrdude over the CH340/FT232 serial" ;;
    esp32-s3*|esp32-c3*|weactstudio_esp32c3*) echo "./$NAME build $project -e $env -t upload --upload-port /dev/ttyUSB0    # esptool; BOOT+RST if auto-reset fails" ;;
    pico) echo "# BOOTSEL drive: cp $workspace/build/$env/firmware.uf2 /run/media/\$USER/RPI-RP2/"
          echo "./$NAME build $project -e $env -t upload    # picotool/mbed copy (board in BOOTSEL)" ;;
    blackpill*|genericSTM32*|weact_*) echo "./$NAME build $project -e $env -t upload --upload-port /dev/ttyACM0    # protocol ${protocol:-stlink} (dfu: BOOT0+reset, ST-Link: SWD)" ;;
    *) echo "./$NAME build $project -e $env -t upload" ;;
  esac
}

# plan <project> [-e env]: print, never run.
tool_cmd_plan() {
  [[ -n "${1:-}" ]] || usage_error "usage: ./$NAME plan <project-dir|example> [-e env]"
  local project only_env="" env
  project=$(project_dir "$1") || usage_error "no platformio.ini in $1"
  if [[ "${2:-}" == -e ]]; then only_env=${3:-}; fi
  echo "# upload plan for $(basename "$project"): PRINTED ONLY, nothing was run."
  echo "# find the port first (read-only): ./$NAME list"
  while IFS= read -r env; do
    if [[ -z "$only_env" || "$only_env" == "$env" ]]; then plan_env "$project" "$env"; fi
  done < <(project_envs "$project")
}

tool_cmd_pio() {
  activate
  # run inside a project folder: keep its .pio workspace on $OUT too
  if [[ -r "$PWD/platformio.ini" && -z "${PLATFORMIO_WORKSPACE_DIR:-}" ]]; then use_workspace "$PWD"; fi
  if [[ "$DRY" == 1 ]]; then printf '+ pio %s\n' "$*"; return 0; fi
  exec pio "$@"
}

hook_help() { # printed after boxtool's help: tool-specific examples and environment
  cat <<EOF

tool examples
  ./$NAME build blink -e pico                    build examples/blink for the Pico
  ./$NAME utest unit_test_native -e native       Unity tests on the host
  ./$NAME check static_check -e native           cppcheck + clang-tidy (pinned tools)
  ./$NAME plan blink -e nano                     print the upload commands (never uploads)
  ./$NAME new project my_fw --dir ~/fw           project from templates/project
tool environment
  BOXT_JOBS          capped at 4 here (shared machine)
  PLATFORMIO_WORKSPACE_DIR   honoured by "pio-box pio" when already set (else \$OUT/build/pio/<project>)
EOF
}

# ---------- dispatch: boxtool commands, tool_cmd_<name>, unknown -> usage error (exit 2) ----------
boxt_main "$@"
