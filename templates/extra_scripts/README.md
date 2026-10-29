# @NAME@

PlatformIO project from the `extra_scripts` template of 32_14_platformio (`pio-box new extra_scripts @NAME@`).
SCons hooks: `scripts/version.py` (pre) turns `VERSION` into `-DFW_VERSION`, `scripts/manifest.py` (post)
writes `manifest.json` (version, sha256, section sizes) next to the firmware and adds the `fwinfo` target.
Same setup as the `extra_scripts` example (`pio-box examples run extra_scripts`).

```sh
pio-box build . -e blackpill
pio-box build . -e blackpill -t fwinfo
```

The `.pio` workspace goes to `$OUT/build/pio/@NAME@`, never into this folder. Uploads are only printed
(`pio-box plan .`).
