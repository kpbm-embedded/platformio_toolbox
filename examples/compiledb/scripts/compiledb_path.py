# pre-script: put compile_commands.json in $BUILD_DIR (default: the project root) and keep toolchain paths.
Import("env")  # noqa: F821
import os

env.Replace(COMPILATIONDB_PATH=os.path.join("$BUILD_DIR", "compile_commands.json"))  # noqa: F821
env.Replace(COMPILATIONDB_INCLUDE_TOOLCHAIN=True)  # noqa: F821  (adds the toolchain's include dirs)
