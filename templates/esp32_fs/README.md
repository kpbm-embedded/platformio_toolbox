# @NAME@

PlatformIO project from the `esp32_fs` template of 32_14_platformio (`pio-box new esp32_fs @NAME@`).
ESP32-S3 with a custom `partitions.csv` (two OTA slots, LittleFS, core dump) and a LittleFS image built
from `data/`.
Same setup as the `esp32_partitions_fs` example (`pio-box examples run esp32_partitions_fs`).

```sh
pio-box build .
pio-box build . -t buildfs          # littlefs.bin from data/
pio-box plan .                      # then -t upload and -t uploadfs (printed)
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
