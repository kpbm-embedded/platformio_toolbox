# @NAME@

PlatformIO project from the `multi_board` template of 32_14_platformio (`pio-box new multi_board @NAME@`).
One source tree, eight envs: BlackPill F411, WeAct G431 / H743, Pico, ESP32-S3, ESP32-C3, Nano, native.
Shared settings in `[common]` / `[common_stm32]` sections reused with `extends`; per-board `-D` flags.
Same setup as the `multi_env_flags` example (`pio-box examples run multi_env_flags`).

```sh
pio-box build . -e weact_g431 -e esp32c3 -e native
pio-box build .                  # all default envs
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
