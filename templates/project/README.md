# @NAME@

PlatformIO project from the `project` template of 32_14_platformio (`pio-box new project @NAME@`).
Envs: `nano`, `esp32s3`, `pico`, `blackpill` (Arduino framework, pinned platforms) and `native`
(host Unity tests in `test/`).

```sh
pio-box build . -e nano            # workspace (.pio) on $OUT/build/pio/@NAME@
pio-box utest . -e native          # Unity tests on the host gcc
pio-box plan .                     # prints the upload commands (never uploads)
```
