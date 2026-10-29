#!/usr/bin/env bash
# about: compile_commands.json per env (-t compiledb) for clangd, written to the build dir; flags checked (Cortex-M4, M0+, host g++)
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ENVS=(blackpill pico native)
compiledb() { local env args=(); for env in "${ENVS[@]}"; do args+=(-e "$env"); done; "$BOX" build "$EX_DIR" "${args[@]}" -t compiledb; }
case "${1:-run}" in
  build) compiledb ;;
  test)
    compiledb >/dev/null
    [[ ! -e "$EX_DIR/compile_commands.json" ]] && echo "ok    nothing written to the project root" || { echo "FAIL compile_commands.json in the source tree"; exit 1; }
    python3 - "$WORKSPACE/build" <<'PY'
import json, os, sys
build = sys.argv[1]
want = {"blackpill": "-mcpu=cortex-m4", "pico": "-mcpu=cortex-m0plus", "native": "g++"}
for env, flag in want.items():
    entries = json.load(open(os.path.join(build, env, "compile_commands.json")))
    main = [e for e in entries if e["file"].endswith("src/main.cpp")]
    assert main, "%s: src/main.cpp missing" % env
    command = main[0].get("command") or " ".join(main[0]["arguments"])
    assert flag in command, "%s: %s not in %s" % (env, flag, command[:200])
    print("ok    %s: %d entries, main.cpp compiled with %s" % (env, len(entries), flag))
PY
    echo "PASS compiledb (3 compilation databases)" ;;
  run) compiledb ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
