# pre-script: link without the toolchain's crt0/startup files (src/startup.c is the startup) and keep a map file.
Import("env")  # noqa: F821
env.Append(LINKFLAGS=["-nostartfiles", "-Wl,--gc-sections", "-Wl,-Map,${BUILD_DIR}/firmware.map"])  # noqa: F821
