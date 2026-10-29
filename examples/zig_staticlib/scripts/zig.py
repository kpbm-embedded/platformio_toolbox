# pre-script: build ../zig/box_zig.zig as a static library for this env's target with the pinned Zig of
# 32_24_microzig (reached, not copied: $BOX_MICROZIG, else the sibling folder of pio-box) and link it.
Import("env")  # noqa: F821
import os
import subprocess
import sys


def zig_launcher():
    candidates = [os.environ.get("BOX_MICROZIG", "")]
    if os.environ.get("PIO_BOX_ROOT"):
        candidates.append(os.path.join(os.path.dirname(os.environ["PIO_BOX_ROOT"]), "32_24_microzig"))
    for folder in candidates:
        if folder and os.access(os.path.join(folder, "microzig-box"), os.X_OK):
            return os.path.join(folder, "microzig-box")
    return None


launcher = zig_launcher()
if launcher is None:
    sys.stderr.write("skip: 32_24_microzig not found (BOX_MICROZIG or a sibling folder of pio-box)\n")
    env.Exit(3)  # noqa: F821
target = env.GetProjectOption("custom_zig_target")  # noqa: F821
cpu = env.GetProjectOption("custom_zig_cpu", "")  # noqa: F821
out_dir = os.path.join(env.subst("$BUILD_DIR"), "zig")  # noqa: F821
os.makedirs(out_dir, exist_ok=True)
source = os.path.join(env.subst("$PROJECT_DIR"), "zig", "box_zig.zig")  # noqa: F821
command = [launcher, "zig", "build-lib", source, "-O", "ReleaseSmall", "-target", target, "-fPIC",
           "-fno-stack-check", "--cache-dir", os.path.join(out_dir, "cache"),
           "-femit-bin=" + os.path.join(out_dir, "libbox_zig.a")]
if cpu:
    command.insert(-1, "-mcpu=" + cpu)
subprocess.run(command, check=True)
env.Append(LIBPATH=[out_dir], LIBS=["box_zig"])  # noqa: F821
print("zig.py: libbox_zig.a for %s%s" % (target, " (" + cpu + ")" if cpu else ""))
