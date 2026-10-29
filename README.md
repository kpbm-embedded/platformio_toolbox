# 32_14_platformio - PlatformIO Core with pinned platforms

PlatformIO Core (the `pio` CLI), pinned from PyPI inside a pixi env, with pinned dev platforms for your boards
(Arduino Nano, ESP32-S3 / ESP32-C3, Raspberry Pi Pico, BlackPill F411CE, WeAct G431 / H743 / H562) plus `native` for
host unit tests with Unity, and pinned `pio check` tools (cppcheck, clang-tidy).
Use it for multi-board firmware projects driven by a `platformio.ini`. Its core dir is `install/platformio` (never
`~/.platformio`), every project's `.pio` workspace goes to idisk03, telemetry is off. No sudo, no system packages.
The launcher never shadows `pio`.

Status: **ready** (doctor 20 ok, examples 16/16, templates 12/12, smoke 30/30, dry-run 40/40, 2026-10-29).
Launcher: `./pio-box`. Git repo `platformio` (sources only, see `.gitignore`).

## What's included

| Component | Version | Notes |
|---|---|---|
| PlatformIO Core | 6.2.0 | PyPI `platformio==6.2.0`, locked in `pixi.lock` |
| atmelavr (Nano) | 5.3.0 | ~233 MB |
| espressif32 (ESP32-S3) | 8.0.0 | Arduino core 3.3.12, toolchain 14.2.0; ~4.4 GB (xtensa 1.3 GB, riscv32 2.4 GB) |
| raspberrypi (Pico) | 1.20.0 | Arduino-mbed 4.6.0 core (32_13 uses the earlephilhower core); ~705 MB |
| ststm32 (BlackPill) | 20.0.0 | STM32duino framework; ~2.3 GB |
| native | 1.2.1 | host gcc, no packages |
| tool-cppcheck, tool-clangtidy | 1.21100.230717, 1.150005.0 | `pio check`; `config/tools.tsv` (PlatformIO Core 6.2.0's own version specs) |
| tool-mklittlefs | 1.203.210628 | ESP32 `-t buildfs`; `config/tools.tsv` |
| ArduinoJson (example library) | 7.4.3 | `lib_deps` of `lib_deps_json`, into the workspace libdeps |
| gcc/g++ for `-e native` | 14.4.0 | conda-forge (clang 19 on macOS, m2w64-gcc on Windows) |
| Python, pixi | 3.12, 0.81.0 | pixi sha256 pinned in the launcher |

Platforms are pinned in `config/platforms.tsv` and in every example
and template `platformio.ini` (`platform = platformio/<name>@<version>`); `doctor` fails if they disagree.
Tools PlatformIO would fetch on first use are pinned in `config/tools.tsv` and installed by `install`. Packages are verified by PlatformIO's
registry checksums. Core dir 7.4 GB, download cache 1.8 GB.

## Quick start

```sh
cd "$BOX_PLATFORMIO"                       # or: cd $BOX/30_39_tools/32_embedded/32_14_platformio
./pio-box install && ./pio-box doctor      # env + 5 platforms (already installed here), then health checks
./pio-box build blink -e pico              # examples/blink for the Pico; workspace on idisk03
./pio-box utest unit_test_native -e native # Unity tests on the host
./pio-box plan blink -e nano               # PRINTS the upload commands; pio-box never uploads
```

With the Box shell set up once (`box shell install --apply`), the `pio-box` shim works from any folder,
and `box test|doctor|status platformio` run this launcher (`box clean platformio` is a dry run until `--apply`).
Standalone (no Box, or `BOX_INTEGRATION=0`), `./pio-box` keeps its output in this folder.

## Commands

Global option: `--dry-run` / `-n` prints what a command would do. Exit codes: 0 ok, 1 failure, 2 usage error (unknown command or option, or arguments given to `where`, `status`, `doctor`, `bootstrap` or `relocate`), 3 not applicable. `help` ends with this tool's own examples and variables (`tool examples`, `tool environment`).

| Command | What it does | Example |
|---|---|---|
| `install [--no-demos]` | bootstrap + the 5 platforms + `config/tools.tsv` + example packages/libraries + native wrappers | `./pio-box install` |
| `bootstrap` | pinned pixi + env + core downloads (sha-checked) | `./pio-box bootstrap` |
| `update [--check\|--env]` | `--check` (default): pins vs newest upstream; `--env`: re-solve the pixi env (rewrites `pixi.lock`) | `./pio-box update --check` |
| `clean [--all] [--yes]` | move build/log output (`--all`: + install/, .pixi, native/, downloads) to the Trash; dry run unless `--yes` | `./pio-box --dry-run clean --all` |
| `status`, `where`, `doctor` | versions and sizes, paths, health checks (exit 1 on failure) | `./pio-box doctor` |
| `shell [-- cmd ...]` | bash (or a command) with the tools on PATH | `./pio-box shell` |
| `run <cmd> [args]` | one command inside the environment | `./pio-box run pio --version` |
| `platforms [--sizes]` | pinned platforms vs installed; `--sizes`: every package's size | `./pio-box platforms --sizes` |
| `build <project-dir> [-e env] [args]` | `pio run` in a project; workspace on `$BOXT_OUT/build/pio/<name>` | `./pio-box build blink -e pico` |
| `utest <project-dir> [-e env] [args]` | `pio test` (e.g. `-e native`: Unity on the host gcc) | `./pio-box utest unit_test_native -e native` |
| `check <project-dir> [-e env] [args]` | `pio check` (cppcheck, clang-tidy); workspace on `$BOXT_OUT` | `./pio-box check static_check -e clean` |
| `list` | read-only: serial ports (`pio device list` + lsusb filter) | `./pio-box list` |
| `plan <project-dir> [-e env]` | PRINT the upload commands per env, runs nothing | `./pio-box plan blink -e nano` |
| `pio [args]` | raw `pio` with this folder's core dir (pass-through) | `./pio-box pio device list` |
| `new <kind> <name> [--dir D] [--force]` | project from `templates/` (12 kinds, below) | `./pio-box new multi_board my_fw --dir ~/fw` |
| `test [--all]` | `tests/test_smoke.sh`; `--all` adds the dry-run test and examples test | `./pio-box test` |
| `examples list \| run <ex> [args] \| build [ex...] \| test [ex...]` | list, run, build or test the examples | `./pio-box examples test` |
| `native [--print]` | write `native/{native.zsh,native.bash,bin/}` | `./pio-box native` |
| `relocate` | after moving the folder: re-create the pixi env, rewrite `native/` | `./pio-box relocate` |
| `pack [--with-cache] [--out F]` | tarball of this folder (minus envs/build) for another machine | `./pio-box pack --out /tmp/p.tgz` |
| `help`, `-h`, `--help` | the command list | `./pio-box help` |

### Uploading (printed only)

`./pio-box plan <project> [-e env]` prints per env, e.g. `./pio-box build <dir> -e nano -t upload --upload-port /dev/ttyUSB0`.
Pico: copy `firmware.uf2` to the RPI-RP2 drive. BlackPill: `upload_protocol = dfu` (BOOT0 + reset; dfu-util comes with
the platform) or an ST-Link. Find ports first with `./pio-box list`.

## Examples and templates

`./pio-box examples list`, then `examples test` for all 16. No board is needed: every test builds and checks the
artifact (size, symbols, sections, image headers) or runs on the host; uploads are only printed (`plan`).

| Example | Envs | What it shows |
|---|---|---|
| `blink` | nano, esp32s3, pico, blackpill | `LED_BUILTIN` toggle + uptime (Arduino framework) |
| `serial_echo` | all four | line echo at 115200 |
| `i2c_scan` | all four | `Wire` scan 0x08..0x77 |
| `unit_test_native` | native, nano, blackpill | ring-buffer library: 4 Unity tests on the host (`pio test -e native`), host program, same lib in firmware |
| `multi_env_flags` | blackpill, weact_g431, weact_h743, esp32c3, native | `[common]` sections + `extends`, per-env `-D` flags, `build_unflags`, `build_src_filter`; strings checked in each binary |
| `custom_board` | weact_h562 | own board JSON (`boards/weact_h562rg.json`, WeAct STM32H562 core board, Cortex-M33); ELF arch, vector table, SRAM checked |
| `extra_scripts` | blackpill, pico | pre-script turns `VERSION` into `-D` flags, post-action writes `manifest.json` (sha256, sections), custom target `fwinfo` |
| `library_package` | native, nano, pico | `library.json` library: 5 Unity tests (CRC check values), `pio ci` builds its example for 2 boards, `pio pkg pack` tarball checked |
| `static_check` | native, blackpill | `pio check`: zero-defect gate on clean code; 3 planted bugs reported by both cppcheck and clang-tidy |
| `size_budget` | nano, blackpill | post-script flash/RAM budgets (`custom_*_budget`), `board_upload.maximum_size`; 2 envs fail on purpose; `-t size` |
| `esp32_freertos` | esp32s3, esp32c3 | FreeRTOS queue, mutex, event group; tasks pinned to 2 cores (S3) or 1 (C3); symbols + image magic checked |
| `native_test_suites` | native, blackpill | 3 Unity suites (10 cases), `-f` filter, `test_build_src`, `test_ignore`; BlackPill test firmware built without a board |
| `lib_deps_json` | native, esp32c3, blackpill | registry library pinned exactly (`bblanchon/ArduinoJson@7.4.3`) in a local lib; 5 host tests |
| `baremetal_ldscript` | blackpill | no framework: own startup + linker script, register blink; vector table, SP, reset vector, map file checked (276 bytes) |
| `compiledb` | blackpill, pico, native | `-t compiledb` into the build dir (not the project root); `-mcpu` per env checked |
| `esp32_partitions_fs` | esp32s3 | custom `partitions.csv` (2 OTA slots, LittleFS, coredump), LittleFS image from `data/` (`-t buildfs`); `partitions.bin` decoded |

Artifacts checked: `firmware.hex` (Nano), `firmware.bin` (ESP32, STM32), `firmware.uf2` (Pico), `program` (native).

Templates (`./pio-box new <kind> <name> [--dir D]`; each has a README with its commands). `tests/test_smoke.sh`
instantiates every kind and builds it, runs its tests or its check:

| Kind | What you get | Smoke check |
|---|---|---|
| `project` | nano (default), esp32s3, pico, blackpill, native envs, `src/main.cpp`, `test/test_basic` | build nano + utest native |
| `multi_board` | 8 envs (BlackPill, WeAct G431/H743, Pico, ESP32-S3/C3, Nano, native) via `[common]` + `extends` | build all 8 |
| `custom_board` | `boards/weact_h562rg.json` + project for it | build |
| `extra_scripts` | `VERSION` + pre/post scripts, `fwinfo` target | build blackpill `-t fwinfo` |
| `library` | `library.json` library with tests, `examples/`, pack settings | utest native (5) |
| `static_check` | `pio check` envs (cppcheck + clang-tidy) and a `buggy/` sample | check clean, zero defects |
| `size_budget` | flash/RAM budget script and `maximum_size` override | build nano + blackpill |
| `esp32_freertos` | FreeRTOS tasks/queue/mutex for ESP32-S3 and C3 | build both |
| `unit_suites` | several Unity suites, `test_build_src`, embedded test build | utest native (10) |
| `lib_deps` | pinned registry library (ArduinoJson) in a local lib, host tests | utest native (5) |
| `baremetal_stm32` | BlackPill without framework (startup, linker script) | build |
| `esp32_fs` | partitions.csv + LittleFS `data/` | build + `-t buildfs` |
| `compiledb` | `compile_commands.json` in the build dir | build blackpill `-t compiledb` |

## Configuration and environment variables

| Variable | Default | Meaning |
|---|---|---|
| `BOXT_OUT` | same ID path on idisk03, else the ID folder | output root (`build/`, `log/`); also settable in `config/local.env` |
| `BOXT_JOBS` | 8 (maximum) here the launcher caps it at 4 | parallel jobs |
| `BOXT_MIN_FREE_GB` | 8 | pause builds while less RAM is free |
| `BOXT_RAM_WAIT_MAX` | 3600 | give up waiting for RAM after this many seconds |
| `BOXT_NET_TIMEOUT` | 3600 | seconds for one download |
| `BOXT_PLATFORM` | detected (`linux-x64`) | override the platform |
| `GITHUB_TOKEN` | unset | optional; lifts the GitHub API limit for `update --check` |
| `BOX_INTEGRATION` | 1 | `0` = standalone: ignore `$BOX`/`$BOX_V3`, keep output in this folder |
| `NO_COLOR` | unset | set to print plain text (colour is only used on a terminal anyway) |
| `PLATFORMIO_CORE_DIR` | `install/platformio` | set by `pio-box`: platforms, packages, appstate (telemetry off) |
| `PLATFORMIO_CACHE_DIR` | `cache/platformio` | set by `pio-box`: downloads, http cache |
| `PLATFORMIO_WORKSPACE_DIR` | `$BOXT_OUT/build/pio/<project>` | per project; honoured by `pio-box pio` when already set |
| `PLATFORMIO_SETTING_ENABLE_TELEMETRY` | `no` | set by `pio-box`; also stored in the core dir at install |
| `BOX_NATIVE_OFF_PLATFORMIO` | unset | `1` skips native mode for one shell (old name `PIO_BOX_NATIVE_OFF` still honoured) |
| `BOX_PLATFORMIO` | set by `box_env.sh` | path of this ID, used by the native snippet |

## Where files go

| What | Where |
|---|---|
| Source, launcher, examples, templates, `config/platforms.tsv`, `config/tools.tsv` | this ID |
| Tools | `.pixi/` (929 MB: python 3.12, platformio, gcc 14), `install/platformio` (7.4 GB), `.bin/` (77 MB pixi) |
| Cache | `cache/` (2.7 GB: PlatformIO downloads 1.8 GB, pixi, pip, XDG; `CACHEDIR.TAG`) |
| Build output and logs | `$BOX_V3/30_39_tools/32_embedded/32_14_platformio/{build,log}` (94 MB after the examples; `build/pio/<project>`) |

ID total about 11 GB on idisk01. `clean [--all] --yes` moves regenerable parts to the Trash (logged in
`$BOX/00_09_meta/02_logs/2026_10_24_box_trash.tsv`).

## Native mode

`./pio-box native` writes `native/native.{zsh,bash}` plus `native/bin/pio` and `native/bin/platformio` (both run
`pio-box pio`, so the core dir and telemetry setting always apply). Load it in every shell (zsh, bash, fish) with `box
native enable platformio --apply`: it runs `./pio-box native` when the files are missing and rebuilds
`box_env.d/native.*` (without `--apply` it only shows the plan; `box native disable platformio --apply` undoes it).
`BOX_NATIVE_OFF_PLATFORMIO=1` skips it for one shell (the old `PIO_BOX_NATIVE_OFF` still works for now). Without Box,
source `native/native.zsh` or `native/native.bash` from your shell rc.

## Tests

```sh
./pio-box test --all       # smoke + dry-run + examples
tests/test_smoke.sh        # pio, core dir, telemetry, platforms, tools, every template built/tested, plan, ~/.platformio untouched
tests/test_dry_run.sh      # every command in --dry-run + shellcheck
```

Last known (2026-10-29): doctor 20 ok / 0 warn / 0 fail; examples 16/16; smoke 30/30 (13 template kinds); dry-run 40/40.

Fresh clone (what a new machine does): `git clone ... && cd platformio && ./pio-box install && ./pio-box doctor &&
./pio-box test --all`. Everything is fetched by the launcher: pixi (sha256 in `pio-box`), the env (`pixi.lock`),
platforms (`config/platforms.tsv`), tools (`config/tools.tsv`), example packages and libraries (registry checksums).

## Troubleshooting

| Symptom | Fix |
|---|---|
| `Permission denied` on the serial port | join `uucp` (`sudo usermod -aG uucp "$USER"`, log in again) or install the udev rules (below) |
| `doctor` fails on platform pins | `config/platforms.tsv` and a `platformio.ini` disagree; make both use the same `platformio/<name>@<version>` |
| BlackPill DFU upload not found | hold BOOT0 and reset first; `upload_protocol = dfu` uses the platform's dfu-util |
| Files appear in `~/.platformio` | they should not; run `tests/test_smoke.sh`, which checks it stays untouched |
| Folder was moved | `./pio-box relocate` (the core dir has no absolute paths) |

## Limitations / needs you

- **Serial access (sudo, once):** `sudo usermod -aG uucp "$USER"` (`dialout` on Debian), log out and in, or install the uaccess rules shipped here:

```sh
sudo install -m 644 udev/70-box-platformio.rules /etc/udev/rules.d/
sudo udevadm control --reload && sudo udevadm trigger
```

  PlatformIO's own `99-platformio-udev.rules` covers many more boards; it is not needed for these four.
- **Size:** 11 GB, mostly espressif32 (4.4 GB) and ststm32 (2.3 GB) plus a 1.8 GB download cache. Your decision whether to trim.
- **Hardware:** nothing was uploaded; uploads are only printed. Not verified here: real boards, the board side of
  the embedded Unity tests (`native_test_suites` builds them with `--without-uploading --without-testing`), LittleFS
  mounting on an ESP32, the FreeRTOS tasks running, the custom H562 board JSON on a real WeAct board.
- `plan` reads `upload_protocol` from the env's own section only; a value inherited through `extends` shows as the default.
- clang-tidy (`tool-clangtidy` 15) ships no clang resource headers and gets gcc 14's predefined macros from PlatformIO, so
  code that includes libc headers fails to parse and PlatformIO still prints "No defects found". See `static_check`.
- Not covered yet: nRF52840 (nice!nano), CH32V003, K210, Pico 2 (RP2350): they need other platforms (nordicnrf52,
  community ch32v, kendryte210, the earlephilhower raspberrypi fork); not pinned here.
- Other OSes: the env is locked for macOS, Linux arm64 and Windows (Git Bash/MSYS2); untested.
- Licences: PlatformIO Core and platforms Apache-2.0; Arduino cores LGPL-2.1; ESP-IDF libs and Mbed OS Apache-2.0; toolchains GPL with runtime exceptions.

## Scripts

Each script has a `[scripts.*]` descriptor in `.box.toml` (`box scripts show 32_14`; `box scripts check 32_14` must stay clean).

| File | Purpose |
|---|---|
| `pio-box` | launcher (POSIX sh): bootstraps the pinned pixi, keeps caches in this folder, then runs `lib/` |
| `lib/boxtool.bash` | shared launcher framework (boxtool 3: bootstrap, pinned downloads, pixi env, every common command); byte-identical copy of `$BOX/00_09_meta/05_policy/templates/tool/lib/boxtool.bash` (edit there, then sync) |
| `lib/platformio.bash` | this tool's hooks and extra commands (job cap 4, core dir, telemetry) |
| `examples/common.sh`, `examples/*/example.sh` | shared example code (build, artifact, symbol and section checks) and the 16 examples |
| `tests/test_smoke.sh`, `tests/test_dry_run.sh`, `tests/testlib.sh` | smoke test, dry-run/shellcheck test, shared helpers |
| `native/` | written by `./pio-box native`; regenerate, do not edit |

## Links

- PlatformIO Core: <https://github.com/platformio/platformio-core/releases/tag/v6.2.0>
- Platforms: <https://github.com/platformio/platform-atmelavr>, <https://github.com/platformio/platform-espressif32>, <https://github.com/platformio/platform-raspberrypi>, <https://github.com/platformio/platform-ststm32>, <https://github.com/platformio/platform-native>
- pixi: <https://github.com/prefix-dev/pixi>
- History: `NOTES.md`. Report: `$BOX/00_09_meta/02_logs/2026_10_25_embedded_tools2_report.md`.
- Sibling tools: `32_13_arduino` (Arduino CLI, same boards), `32_15_flashers`, `32_20_testing`.
