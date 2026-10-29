# @NAME@

PlatformIO project from the `static_check` template of 32_14_platformio (`pio-box new static_check @NAME@`).
`pio check` gate with cppcheck + clang-tidy (tools pinned in pio-box's config/tools.tsv). `buggy/` holds
planted bugs to see what the tools report; delete it once you trust the setup. Keep analysed native code
free of libc headers or give clang-tidy a working include path (see platformio.ini).
Same setup as the `static_check` example (`pio-box examples run static_check`).

```sh
pio-box check . -e clean --fail-on-defect low
pio-box check . -e buggy             # reports 3 bugs per tool
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
