# @NAME@

PlatformIO project from the `zig_lib` template of 32_14_platformio (`pio-box new zig_lib @NAME@`).
Zig code built as a static library by a pre-script and linked into C/C++ (header in `include/`): Unity tests
on the host (`native`) and Arduino firmware for two boards. PlatformIO itself has no Zig support; the
toolchain is the pinned one of 32_24_microzig (`$BOX_MICROZIG`, else the sibling folder of pio-box), reached, not installed here. Without it the build stops (exit 3).
Same setup as the `zig_staticlib` example.

```sh
pio-box utest . -e native
pio-box build . -e blackpill
"$BOX_MICROZIG/microzig-box" zig test zig/box_zig.zig                       # Zig unit tests
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder.
