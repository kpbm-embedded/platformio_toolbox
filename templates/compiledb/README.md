# @NAME@

PlatformIO project from the `compiledb` template of 32_14_platformio (`pio-box new compiledb @NAME@`).
`compile_commands.json` for clangd/IDEs per env, written into the env's build folder (not the project root).
Same setup as the `compiledb` example (`pio-box examples run compiledb`).

```sh
pio-box build . -e blackpill -t compiledb
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
