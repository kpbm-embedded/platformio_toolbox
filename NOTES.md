# 32_14_platformio: notes

## 2026-10-25: created
- New ID in the Box tool style (launcher `pio-box`, `lib/boxtool.bash` copied unchanged from
  32_10_qemu; pixi binary copied from there).
- PlatformIO Core 6.2.0 from PyPI in the pixi env (python 3.12, gcc/g++ 14.4 for `-e native`);
  pixi.lock solved for linux-64/aarch64, osx-64/arm64 (clang 19), win-64 (m2w64-gcc).
- Platforms (newest each, config/platforms.tsv = example platformio.ini pins): atmelavr 5.3.0
  (35 s), espressif32 8.0.0 (412 s; 6 days old but it is the release that carries Arduino core
  3.3.12, the same as 32_13_arduino), raspberrypi 1.20.0 (36 s), ststm32 20.0.0 (85 s), native 1.2.1.
  Sizes: avr ~233 MB, espressif32 ~4.4 GB (the RISC-V toolchain is pulled for the S3 ULP),
  raspberrypi ~705 MB, ststm32 ~2.3 GB (two arm-none-eabi toolchains: 7.2.1 from the global
  platform install, 13.x for the framework). Core dir 7.4 GB, download cache 1.8 GB.
- Workspaces: `PLATFORMIO_WORKSPACE_DIR=$OUT/build/pio/<project>` (no `.pio` in source folders);
  `pio-box pio` sets it too when run inside a project. `plan` prints `pio-box build ... -t upload`
  rather than raw `pio run -d`, which would have created `.pio` in the project.
- Telemetry: `pio settings set enable_telemetry no` (core dir) + env setting; check interval 3650 d.
- Mistakes fixed: unit_test_native first checked the host program after `pio test`, which rebuilds
  `build/native/program` as the test runner; the check now runs before the tests. Same doctor
  `set -e`/`stat` issue as 32_13 (fixed with `|| true`). Shellcheck SC2155/SC2013/SC2119 fixed.
- Results: doctor 17 ok / 0 failed, examples test 4/4 (blink 112 s incl. first framework builds,
  i2c_scan 45 s, serial_echo 25 s, unit_test_native 5 s; 15 artifacts + 4 Unity cases),
  tests/test_smoke.sh 13/13, tests/test_dry_run.sh 30/30. ~/.platformio stayed empty.
- Needs the user: serial access (`uucp` group or udev/70-box-platformio.rules, sudo).

## 2026-10-25: readability pass 2 (script_style.md, scripts/README)
- lib/boxtool.bash (reference `00_09_meta/05_policy/templates/tool/lib/boxtool.bash`, synced to all 24 copies):
  `where`/`status`/`doctor`/`bootstrap`/`relocate` reject extra arguments (exit 2); colour only on a terminal
  and never with `NO_COLOR`; help lists `NO_COLOR`.
- README: exit codes, `BOX_INTEGRATION` and `NO_COLOR` rows. Backups:
  `00_09_meta/02_logs/config_backups/2026_10_25_readability2_embedded_tools/`.

## 2026-10-29: 12 examples, 12 templates, `check` command, git repo
- New examples (all hardware-free, artifacts checked): `multi_env_flags`, `custom_board` (WeAct H562 board JSON),
  `extra_scripts`, `library_package`, `static_check`, `size_budget`, `esp32_freertos`, `native_test_suites`,
  `lib_deps_json`, `baremetal_ldscript`, `compiledb`, `esp32_partitions_fs`. New boards used: WeAct G431
  (genericSTM32G431CB), WeAct H743 (weact_mini_h743vitx), WeAct H562 (own JSON, STM32duino variant H562R(G-I)T),
  ESP32-C3 (weactstudio_esp32c3coreboard; `install` fetches the C3 Arduino libs).
- New templates: `multi_board`, `custom_board`, `extra_scripts`, `library`, `static_check`, `size_budget`,
  `esp32_freertos`, `unit_suites`, `lib_deps`, `baremetal_stm32`, `esp32_fs`, `compiledb`. test_smoke.sh now
  instantiates every kind with `new` and builds / tests / checks it.
- Launcher: `check` (pio check with the workspace on $OUT); `config/tools.tsv` pins tool-cppcheck 1.21100.230717,
  tool-clangtidy 1.150005.0 (the specs of PlatformIO Core 6.2.0) and tool-mklittlefs 1.203.210628, installed by
  `install` and checked by doctor; doctor checks the platform pins of templates too; `plan` knows the C3 and
  WeAct boards. examples/common.sh: `elf`, `tc_bin`, `need_symbols`, `section_addr`, `ex_utest`.
- Problems found: a shared `PLATFORMIO_BUILD_CACHE_DIR` was tried and dropped: an ELF taken from the cache skips
  `AddPostAction` (no manifest.json, no budget check). In post-actions `target[0]` is the ELF, `source[0]` the first
  object file. clang-tidy 15 from the registry has no resource headers and gets gcc 14's macros (incl.
  `__cplusplus` for C files): libc headers fail to parse and PlatformIO still reports "No defects found"; the
  static_check example keeps analysed code free of libc headers and asserts that the planted bugs are reported.
  `pio test` on an embedded env with `--without-uploading --without-testing` reports built suites as SKIPPED.
  cppcheck 2.11 aborts on the STM32 core headers (`check_skip_packages = no`), so the blackpill check skips them.
- Git: `git init -b main`; `.gitignore` keeps out .bin, .pixi, cache (also as a symlink), install (core dir), native, build, log,
  `.pio`, compile_commands.json, tarballs.
- Results: doctor 20 ok / 0 warn / 0 fail; examples 16/16; smoke 30/30 (13 template kinds); dry-run 40/40
  (shellcheck clean).
- Fresh clone (idisk03, cache/ symlinked, BOX_INTEGRATION=0): install (pixi, env, 5 platforms, 3 tools, example
  packages) ok; doctor 20 ok; test --all: smoke 30/30, dry-run 40/40, examples 16/16. Only finding: `/cache/` did
  not match the symlinked cache, now `/cache`.

## 2026-10-29: Rust, Zig and BEAM (brief addendum)
- PlatformIO has no Rust, Zig or Erlang support (no builders, frameworks or platforms). What fits: a pre-build
  `extra_scripts` step that runs another ID's pinned toolchain and links a static library into C/C++.
- Rust: `rust_staticlib` example + `rust_lib` template. no_std crate (`#![cfg_attr(not(test), no_std)]`, panic=abort)
  built by scripts/cargo.py with `rust-box cargo` of 32_17_embedded_rust (`$BOX_EMBEDDED_RUST`, else the sibling
  folder) for x86_64-unknown-linux-gnu / thumbv7em-none-eabihf / thumbv6m-none-eabi. `cargo test` needs `--lib`
  (the staticlib build of the crate is no_std and cannot unwind). Results: cargo test 2, Unity 3, BlackPill + Pico.
- Zig: `zig_staticlib` example + `zig_lib` template. `microzig-box zig build-lib` (Zig 0.17.0 of 32_24_microzig)
  with -fPIC for the PIE host program, thumb-freestanding-eabihf cortex_m4 (hard float like the STM32 core), riscv32
  generic_rv32+m+c for the ESP32-C3. Results: zig test 2, Unity 3, BlackPill + ESP32-C3.
- Missing toolchain ID: example.sh prints `skip: ...` and exits 3 (boxtool's summary shows that as FAIL);
  the pre-scripts stop the build with exit 3; the smoke test prints `skip` for the two templates.
- BEAM: skipped. AtomVM is a VM firmware built by its own ESP-IDF/CMake/Pico SDK build (32_29_atomvm); there is no
  PlatformIO build of it and nothing to link into an Arduino project.
- Results: doctor 20 ok; examples 18/18; smoke 32/32; dry-run 42/42 (shellcheck clean).
- Fresh clone (second run): found that `sibling_launcher` printed its skip message on stdout, inside the captured
  path; now stderr (checked: both examples print `skip: ...` and exit 3 without the other IDs). That run stopped on
  `No space left on device`: idisk03 filled up (shared; about 60 GB of earlier clone checks sit in its Trash) after
  install, doctor 20 ok, smoke 32/32 and dry-run 42/42 had passed in the clone.
