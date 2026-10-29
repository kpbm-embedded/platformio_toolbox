# @NAME@

PlatformIO project from the `custom_board` template of 32_14_platformio (`pio-box new custom_board @NAME@`).
A board PlatformIO does not ship: `boards/weact_h562rg.json` (WeAct STM32H562RGT6 core board, Cortex-M33,
STM32duino variant). Copy the JSON and change mcu/variant/memory sizes for another board.
Same setup as the `custom_board` example (`pio-box examples run custom_board`).

```sh
pio-box build .
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
