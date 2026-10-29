#!/usr/bin/env bash
# about: extra_scripts: pre-script injects VERSION into -D flags, post-action writes manifest.json, custom target fwinfo (BlackPill, Pico)
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
ENVS=(blackpill pico)
case "${1:-run}" in
  build) ex_build "${ENVS[@]}" ;;
  test)
    ex_build "${ENVS[@]}"
    ex_check "${ENVS[@]}"
    version=$(cat "$EX_DIR/VERSION")
    for env in "${ENVS[@]}"; do
      manifest="$WORKSPACE/build/$env/manifest.json"
      python3 - "$manifest" "$(elf "$env")" "$version" "$env" <<'PY'
import hashlib, json, sys
manifest, elf, version, env = sys.argv[1:]
data = json.load(open(manifest))
assert data["version"] == version, data["version"]
assert data["env"] == env, data["env"]
assert data["elf_sha256"] == hashlib.sha256(open(elf, "rb").read()).hexdigest(), "sha256"
assert data["sections"].get(".text", 0) > 1000, data["sections"]
print("ok    %s manifest: version %s, .text %d bytes, sha256 matches" % (env, version, data["sections"][".text"]))
PY
      grep -aq "fw $version env $env" "$(elf "$env")" && echo "ok    $env: version string in the ELF" || { echo "FAIL version string ($env)"; exit 1; }
    done
    info=$("$BOX" build "$EX_DIR" -e blackpill -t fwinfo 2>&1) || { echo "$info"; exit 1; }
    grep -q '"elf_sha256"' <<<"$info" && echo "ok    custom target fwinfo" || { echo "FAIL fwinfo"; exit 1; }
    echo "PASS extra_scripts (pre + post script, custom target)" ;;
  run) "$BOX" build "$EX_DIR" -e blackpill -t fwinfo ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
