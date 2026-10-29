# pre-script: runs before the build; puts the VERSION file and the env name into the compile flags.
Import("env")  # noqa: F821  (SCons injects Import/env)
import os

version_file = os.path.join(env.subst("$PROJECT_DIR"), "VERSION")  # noqa: F821
with open(version_file, encoding="utf-8") as handle:
    version = handle.read().strip()
env.Append(CPPDEFINES=[("FW_VERSION", env.StringifyMacro(version)),  # noqa: F821
                       ("FW_ENV", env.StringifyMacro(env.subst("$PIOENV")))])  # noqa: F821
print("version.py: FW_VERSION=%s for %s" % (version, env.subst("$PIOENV")))  # noqa: F821
