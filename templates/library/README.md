# @NAME@

PlatformIO library from the `library` template of 32_14_platformio (`pio-box new library @NAME@`).
`library.json` + `src/` (sample code: table-free CRC-8/16/32), Unity tests in `test/` run on the host,
`examples/checksum` built for boards with `pio ci`, `pio pkg pack` makes the publishable tarball
(`test/` and `platformio.ini` excluded by `export.exclude`). Same setup as the `library_package` example.

```sh
pio-box utest . -e native
pio-box run pio ci examples/checksum --lib . --project-conf platformio.ini -e nano -e pico
pio-box run pio pkg pack . -o /tmp/
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder.
