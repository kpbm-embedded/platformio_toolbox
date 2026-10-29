# post-script: after the ELF is linked, write manifest.json next to it; add the `fwinfo` target.
Import("env")  # noqa: F821
import hashlib
import json
import os
import subprocess


def write_manifest(source, target, env):
    elf = str(target[0])  # target = the linked ELF (source = its object files)
    size_tool = env.subst("$SIZETOOL")
    lines = subprocess.run([size_tool, "-A", elf], check=True, capture_output=True, text=True).stdout.splitlines()
    sections = {}
    for line in lines:
        parts = line.split()
        if len(parts) >= 3 and parts[0].startswith(".") and parts[1].isdigit():
            sections[parts[0]] = int(parts[1])
    with open(elf, "rb") as handle:
        digest = hashlib.sha256(handle.read()).hexdigest()
    manifest = {
        "env": env.subst("$PIOENV"),
        "board": env.subst("$BOARD"),
        "version": open(os.path.join(env.subst("$PROJECT_DIR"), "VERSION"), encoding="utf-8").read().strip(),
        "elf_sha256": digest,
        "sections": sections,
    }
    path = os.path.join(env.subst("$BUILD_DIR"), "manifest.json")
    with open(path, "w", encoding="utf-8") as handle:
        json.dump(manifest, handle, indent=2, sort_keys=True)
    print("manifest.py: wrote %s" % path)


env.AddPostAction("$BUILD_DIR/${PROGNAME}.elf", write_manifest)  # noqa: F821
env.AddCustomTarget(  # noqa: F821
    name="fwinfo",
    dependencies="$BUILD_DIR/${PROGNAME}.elf",
    actions=["cat $BUILD_DIR/manifest.json"],
    title="Firmware info",
    description="Print manifest.json of this env",
)
