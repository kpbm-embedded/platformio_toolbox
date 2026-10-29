# @NAME@

PlatformIO project from the `esp32_freertos` template of 32_14_platformio (`pio-box new esp32_freertos @NAME@`).
FreeRTOS tasks on the Arduino-ESP32 core: queue, mutex, event group; tasks pinned to both cores on the
ESP32-S3, single core on the ESP32-C3.
Same setup as the `esp32_freertos` example (`pio-box examples run esp32_freertos`).

```sh
pio-box build . -e esp32s3 -e esp32c3
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
