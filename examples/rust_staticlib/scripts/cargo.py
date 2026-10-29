# pre-script: build ../rust as a static library for this env's Rust target with the pinned toolchain of
# 32_17_embedded_rust (reached, not copied: $BOX_EMBEDDED_RUST, else the sibling folder of pio-box) and link it.
Import("env")  # noqa: F821
import os
import subprocess
import sys


def rust_launcher():
    candidates = [os.environ.get("BOX_EMBEDDED_RUST", "")]
    if os.environ.get("PIO_BOX_ROOT"):
        candidates.append(os.path.join(os.path.dirname(os.environ["PIO_BOX_ROOT"]), "32_17_embedded_rust"))
    for folder in candidates:
        if folder and os.access(os.path.join(folder, "rust-box"), os.X_OK):
            return os.path.join(folder, "rust-box")
    return None


target = env.GetProjectOption("custom_rust_target")  # noqa: F821
launcher = rust_launcher()
if launcher is None:
    sys.stderr.write("skip: 32_17_embedded_rust not found (BOX_EMBEDDED_RUST or a sibling folder of pio-box)\n")
    env.Exit(3)  # noqa: F821
manifest = os.path.join(env.subst("$PROJECT_DIR"), "rust", "Cargo.toml")  # noqa: F821
target_dir = os.path.join(env.subst("$BUILD_DIR"), "cargo")  # noqa: F821
subprocess.run([launcher, "cargo", "build", "--release", "--quiet", "--manifest-path", manifest,
                "--target", target, "--target-dir", target_dir], check=True)
env.Append(LIBPATH=[os.path.join(target_dir, target, "release")], LIBS=["box_rust"])  # noqa: F821
print("cargo.py: libbox_rust.a for %s" % target)
