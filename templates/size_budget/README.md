# @NAME@

PlatformIO project from the `size_budget` template of 32_14_platformio (`pio-box new size_budget @NAME@`).
Flash/RAM budgets per env (`custom_flash_budget`, `custom_ram_budget`) enforced by `scripts/budget.py` after
linking, and PlatformIO's own `board_upload.maximum_size` check. `nano_tight` and `nano_small_board` fail on purpose.
Same setup as the `size_budget` example (`pio-box examples run size_budget`).

```sh
pio-box build . -e nano -e blackpill
pio-box build . -e nano -t size
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
