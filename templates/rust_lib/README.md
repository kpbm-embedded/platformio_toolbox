# @NAME@

PlatformIO project from the `rust_lib` template of 32_14_platformio (`pio-box new rust_lib @NAME@`).
Rust code built as a static library by a pre-script and linked into C/C++ (header in `include/`): Unity tests
on the host (`native`) and Arduino firmware for two boards. PlatformIO itself has no Rust support; the
toolchain is the pinned one of 32_17_embedded_rust (`$BOX_EMBEDDED_RUST`, else the sibling folder of pio-box), reached, not installed here. Without it the build stops (exit 3).
Same setup as the `rust_staticlib` example.

```sh
pio-box utest . -e native
pio-box build . -e blackpill
"$BOX_EMBEDDED_RUST/rust-box" cargo test --lib --manifest-path rust/Cargo.toml   # Rust unit tests
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder.
