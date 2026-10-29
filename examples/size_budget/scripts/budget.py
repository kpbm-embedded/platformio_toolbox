# post-script: after linking, compare flash (text+data) and RAM (data+bss) with custom_*_budget.
Import("env")  # noqa: F821
import subprocess


def check_budget(source, target, env):
    elf = str(target[0])
    out = subprocess.run([env.subst("$SIZETOOL"), "-B", "-d", elf], check=True, capture_output=True, text=True).stdout
    text, data, bss = (int(v) for v in out.splitlines()[1].split()[:3])
    flash, ram = text + data, data + bss
    flash_budget = int(env.GetProjectOption("custom_flash_budget", "0"))
    ram_budget = int(env.GetProjectOption("custom_ram_budget", "0"))
    print("budget.py: flash %d / %d bytes, ram %d / %d bytes" % (flash, flash_budget, ram, ram_budget))
    failed = (flash_budget and flash > flash_budget) or (ram_budget and ram > ram_budget)
    if failed:
        print("budget.py: OVER BUDGET")
        env.Exit(1)


env.AddPostAction("$BUILD_DIR/${PROGNAME}.elf", check_budget)  # noqa: F821
