#!/usr/bin/env bash
# about: ESP32-S3 custom partitions.csv (2 OTA slots + LittleFS + coredump) and a LittleFS image from data/ (-t buildfs) checked
# Usage (through ./pio-box examples ...): example.sh build | test | run
# shellcheck disable=SC2015  # `test && echo ok || { echo FAIL; exit 1; }`: echo does not fail
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=../common.sh
. "$(dirname "$0")/../common.sh"
fs_image() { echo "$WORKSPACE/build/esp32s3/littlefs.bin"; }
case "${1:-run}" in
  build) ex_build esp32s3; "$BOX" build "$EX_DIR" -e esp32s3 -t buildfs ;;
  test)
    ex_build esp32s3
    ex_check esp32s3
    "$BOX" build "$EX_DIR" -e esp32s3 -t buildfs >/dev/null
    size=$(stat -c %s "$(fs_image)")
    [[ "$size" == $((0xE0000)) ]] && echo "ok    littlefs.bin $size bytes = size of the spiffs partition (0xE0000)" || { echo "FAIL littlefs.bin $size bytes"; exit 1; }
    for f in config.json index.html; do
      grep -aq "${f%.*}" "$(fs_image)" && echo "ok    $f in the image" || { echo "FAIL $f not in the image"; exit 1; }
    done
    # the partition table binary: 32-byte entries with magic 0xAA 0x50, label at offset 12
    table="$WORKSPACE/build/esp32s3/partitions.bin"
    labels=$(python3 - "$table" <<'PY'
import struct, sys
data = open(sys.argv[1], "rb").read()
out = []
for i in range(0, len(data), 32):
    entry = data[i:i + 32]
    if entry[:2] != b"\xaa\x50":
        break
    offset, size = struct.unpack_from("<II", entry, 4)
    out.append("%s@0x%x+0x%x" % (entry[12:28].rstrip(b"\0").decode(), offset, size))
print(" ".join(out))
PY
)
    [[ "$labels" == *"app0@0x10000+0x180000"*"app1@0x190000+0x180000"*"spiffs@0x310000+0xe0000"*"coredump@0x3f0000+0x10000"* ]] \
      && echo "ok    partitions.bin: $labels" || { echo "FAIL partitions.bin: $labels"; exit 1; }
    app=$(stat -c %s "$(firmware esp32s3)")
    (( app < 0x180000 )) && echo "ok    app $app bytes fits one OTA slot (0x180000)" || { echo "FAIL app too big"; exit 1; }
    echo "PASS esp32_partitions_fs" ;;
  run) ex_run ;;
  *) echo "usage: example.sh build|test|run" >&2; exit 2 ;;
esac
