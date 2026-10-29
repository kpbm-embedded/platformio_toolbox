# @NAME@

PlatformIO project from the `baremetal_stm32` template of 32_14_platformio (`pio-box new baremetal_stm32 @NAME@`).
BlackPill without a framework: own vector table and `Reset_Handler` (`src/startup.c`), own linker script
(`ld/stm32f411ce.ld`), register-level blink of PC13, map file in the build folder.
Same setup as the `baremetal_ldscript` example (`pio-box examples run baremetal_ldscript`).

```sh
pio-box build .
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
