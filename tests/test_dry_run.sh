#!/usr/bin/env bash
# Every pio-box command in --dry-run mode (no downloads, builds, moves or uploads), help and exit
# codes, plus shellcheck of every script. Usage: tests/test_dry_run.sh
# Depends on: tests/testlib.sh, an installed ID for the doctor/platforms lines.
TEST_LAUNCHER_NAME=pio-box
# shellcheck source-path=SCRIPTDIR source=testlib.sh
. "$(dirname "$0")/testlib.sh"
Q=$LAUNCHER

check help        'usage: \./pio-box'                      "$Q" help
check help-flag   'environment'                            "$Q" --help
check help-short  'BOXT_OUT'                               "$Q" -h
check_exit unknown-cmd 2                                   "$Q" no-such-command
check_exit usage-build 2                                   "$Q" build
check_exit no-project 2                                    "$Q" plan /nonexistent
check where       '^root '                                 "$Q" where
check bootstrap   'pixi .*install'                         "$Q" --dry-run bootstrap
check install     'pio pkg install -g -p platformio/espressif32@8\.0\.0|already installed' "$Q" --dry-run install
check update      'pinned vs newest'                       "$Q" --dry-run update
check update-env  '\+ timeout .* update'                   "$Q" --dry-run update --env
check clean       'nothing to clean|dry run: re-run with --yes' "$Q" clean
check clean-all   'dry run: re-run with --yes'             "$Q" clean --all
check status      'platforms .*pinned'                     "$Q" status
check doctor      'doctor: [0-9]+ ok'                      bash -c "'$Q' doctor || true"
check shell       '\+ true'                                "$Q" --dry-run shell -- true
check run         '\+ pio --version'                       "$Q" --dry-run run pio --version
check test        'test_smoke\.sh'                         "$Q" --dry-run test
check new         '\+ copy .*templates/project'            "$Q" --dry-run new project demo --dir /nonexistent
check ex-list     'unit_test_native .*Unity'               "$Q" examples list
check ex-run      'example\.sh run'                        "$Q" --dry-run examples run blink
check ex-build    'example\.sh build'                      "$Q" --dry-run examples build
check ex-test     'example\.sh test'                       "$Q" --dry-run examples test
check native      'pio @pio'                               "$Q" --dry-run native
check relocate    'pixi env already matches|re-creating'   "$Q" --dry-run relocate
check pack        '\+ tar .*-cf .*pio-box_'                "$Q" --dry-run pack
check platforms   'espressif32 +8\.0\.0'                   "$Q" platforms
check build       '\+ pio run -d .*examples/blink -j [1-4] -e pico' "$Q" --dry-run build blink -e pico
check utest       '\+ pio test -d .*unit_test_native -e native' "$Q" --dry-run utest unit_test_native -e native
check check       '\+ pio check -d .*static_check -e clean' "$Q" --dry-run check static_check -e clean
check_exit usage-check 2                                   "$Q" check
check new-library '\+ copy .*templates/library'            "$Q" --dry-run new library demo --dir /nonexistent
check plan-c3     'esptool'                                "$Q" plan esp32_freertos -e esp32c3
check plan-g431   'ttyACM0'                                "$Q" plan multi_env_flags -e weact_g431
check list        '\+ pio device list'                     "$Q" --dry-run list
check plan        'PRINTED ONLY'                           "$Q" plan blink
check plan-pico   'RPI-RP2'                                "$Q" plan blink -e pico
check plan-native 'nothing to upload'                      "$Q" plan unit_test_native -e native
check pio         '\+ pio system info'                     "$Q" --dry-run pio system info
mapfile -t scripts < <(cd "$HERE" && ls pio-box lib/*.bash tests/*.sh examples/common.sh examples/*/example.sh)
check_shellcheck "${scripts[@]}"
finish dry-run
