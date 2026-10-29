# @NAME@

PlatformIO project from the `lib_deps` template of 32_14_platformio (`pio-box new lib_deps @NAME@`).
A registry library pinned to an exact version (`bblanchon/ArduinoJson@7.4.3`) used by a local library
(`lib/config`), unit-tested on the host, linked into ESP32-C3 and BlackPill firmware.
Same setup as the `lib_deps_json` example (`pio-box examples run lib_deps_json`).

```sh
pio-box utest . -e native
pio-box build . -e esp32c3 -e blackpill
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
