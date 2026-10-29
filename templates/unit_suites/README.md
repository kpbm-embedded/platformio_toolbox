# @NAME@

PlatformIO project from the `unit_suites` template of 32_14_platformio (`pio-box new unit_suites @NAME@`).
Several Unity suites (`test/test_*`), code from `src/` under test (`test_build_src`), filtered runs, and
the BlackPill build of the same tests without a board.
Same setup as the `native_test_suites` example (`pio-box examples run native_test_suites`).

```sh
pio-box utest . -e native
pio-box utest . -e native -f test_pid
pio-box utest . -e blackpill --without-uploading --without-testing
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
