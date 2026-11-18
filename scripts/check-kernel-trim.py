#!/usr/bin/env python3
"""Check external/board/rpi/linux-*.fragment against the Raspberry Pi
kernel's Kconfig files, by static analysis (nothing from the kernel tree is
built or run).

Switching an option off can only switch off options that depend on it: via
"depends on", an enclosing "if ... endif", or a "menu" dependency. So for
every option PICO8-OS needs, the full dependency closure must not contain
any option the fragment disables. Also reports how many of each defconfig's
=m / =y lines the trim removes.

usage: check-kernel-trim.py LINUX_SRC_DIR
LINUX_SRC_DIR: raspberrypi/linux at the commit Buildroot builds (the
BR2_LINUX_KERNEL_CUSTOM_TARBALL_LOCATION of the raspberrypi*_defconfigs);
only the Kconfig files and arch/*/configs are needed.
"""
import os
import re
import sys
from pathlib import Path

HERE = os.path.dirname(os.path.abspath(__file__))
FRAGMENTS = sorted(__import__("glob").glob(os.path.join(HERE, "..", "external", "board", "rpi", "linux-*.fragment")))
SYM = re.compile(r"\b[A-Z][A-Z0-9_]+\b")

COMMON = [
    "DRM", "DRM_VC4", "SND", "SND_SOC", "MMC", "EXT4_FS", "VFAT_FS",
    "NLS_CODEPAGE_437", "NLS_ISO8859_1", "USB", "USB_STORAGE", "USB_HID",
    "HID_GENERIC", "HIDRAW", "UHID", "INPUT_EVDEV", "INPUT_JOYDEV",
    "JOYSTICK_XPAD", "HID_SONY", "HID_PLAYSTATION", "HID_NINTENDO",
    "HID_MICROSOFT", "HID_STEAM", "BT", "BT_HCIUART", "BT_HCIUART_BCM",
    "BT_HCIBTUSB", "BT_HIDP", "CFG80211", "BRCMFMAC", "WATCHDOG",
    "BCM2835_WDT", "HWMON", "SENSORS_RASPBERRYPI_HWMON", "STAGING", "INET",
    "IPV6", "PACKET", "UNIX", "VT", "FRAMEBUFFER_CONSOLE", "SND_USB_AUDIO",
    "BLK_DEV_SD", "SCSI", "INPUT", "HID", "NET", "WLAN", "WIRELESS",
]
TARGETS = [
    ("Pi 0/1 (bcmrpi)", "arm", "bcmrpi_defconfig", COMMON + ["SND_BCM2835", "USB_NET_SMSC95XX"]),
    ("Pi 2/3 (bcm2709)", "arm", "bcm2709_defconfig", COMMON + ["SND_BCM2835", "USB_NET_SMSC95XX", "USB_LAN78XX"]),
    ("Pi 4 (bcm2711)", "arm", "bcm2711_defconfig", COMMON + ["DRM_V3D", "BCMGENET", "USB_XHCI_HCD"]),
    ("Pi 5 (bcm2712)", "arm64", "bcm2712_defconfig", COMMON + ["DRM_V3D", "MACB", "USB_XHCI_HCD"]),
]


def parse_kconfig(src, arch):
    """symbol -> set of symbols its visibility depends on (direct)."""
    deps = {}
    seen = set()

    def parse(path, ctx):
        path = os.path.normpath(path)
        if path in seen or not os.path.exists(path):
            return
        seen.add(path)
        stack = []            # (kind, symbols) for if/menu/choice blocks
        cur = None            # symbols list of the entry being defined
        pending_menu = None
        for raw in Path(path).read_text(encoding="utf-8", errors="replace").splitlines():
            line = raw.split("#", 1)[0].strip() if not raw.lstrip().startswith("help") else raw.strip()
            if not line:
                continue
            word = line.split()[0]
            outer = set(ctx)
            for _, s in stack:
                outer |= s
            if word in ("config", "menuconfig") and len(line.split()) > 1:
                name = line.split()[1]
                cur = deps.setdefault(name, set())
                cur |= outer
                pending_menu = None
            elif word in ("depends", "visible") and ("on" in line or "if" in line):
                expr = line.split(None, 2)[2] if len(line.split()) > 2 else ""
                found = set(SYM.findall(expr))
                if pending_menu is not None:
                    pending_menu |= found
                elif cur is not None:
                    cur |= found
            elif word == "if":
                stack.append(("if", set(SYM.findall(line[2:]))))
                cur = None
            elif word == "endif":
                if stack and stack[-1][0] == "if":
                    stack.pop()
                cur = None
            elif word in ("menu", "choice"):
                pending_menu = set()
                stack.append((word, pending_menu))
                cur = None
            elif word in ("endmenu", "endchoice"):
                if stack:
                    stack.pop()
                cur = None
                pending_menu = None
            elif word in ("source", "rsource", "osource", "orsource"):
                m = re.search(r'"([^"]+)"', line)
                if m:
                    rel = m.group(1).replace("$(SRCARCH)", arch).replace("$SRCARCH", arch)
                    base = os.path.dirname(path) if word.startswith(("r", "or")) else src
                    for p in sorted(__import__("glob").glob(os.path.join(base, rel))):
                        parse(p, outer)
            elif word in ("comment", "mainmenu"):
                cur = None

    parse(os.path.join(src, "Kconfig"), set())
    return deps


def closure(deps, sym, memo):
    if sym in memo:
        return memo[sym]
    memo[sym] = set()
    out = set()
    for d in deps.get(sym, ()):
        if d == sym:
            continue
        out.add(d)
        out |= closure(deps, d, memo)
    memo[sym] = out
    return out


def main(src):
    disabled = {line.split()[1][len("CONFIG_"):] for f in FRAGMENTS
                for line in Path(f).read_text().splitlines()
                if line.startswith("# CONFIG_") and line.rstrip().endswith("is not set")}
    bad = 0
    for label, arch, defconfig, needs in TARGETS:
        deps = parse_kconfig(src, arch)
        memo = {}
        lines = Path(src, "arch", arch, "configs", defconfig).read_text().splitlines()
        mods = [line.split("=")[0][7:] for line in lines if line.startswith("CONFIG_") and line.endswith("=m")]
        ys = [line.split("=")[0][7:] for line in lines if line.startswith("CONFIG_") and line.endswith("=y")]
        gone = {s for s in mods + ys if s in disabled or closure(deps, s, memo) & disabled}
        mods_gone = sum(s in gone for s in mods)
        ys_gone = sum(s in gone for s in ys)
        unknown = sorted(s for s in disabled if s not in deps)
        print(f"{label}: defconfig modules {len(mods)} -> {len(mods) - mods_gone} "
              f"({mods_gone} removed), built-in options {len(ys)} -> {len(ys) - ys_gone}")
        for n in needs:
            if n not in deps:
                print(f"  (needed option {n} is not in this kernel)")
                continue
            hit = (closure(deps, n, memo) | {n}) & disabled
            if hit:
                print(f"  LOST {n}: depends on disabled {', '.join(sorted(hit))}")
                bad = 1
        if unknown:
            print(f"  (fragment symbols unknown here, ignored by kconfig: {', '.join(unknown)})")
    print("OK: every needed option survives the trim" if not bad else "FAILED")
    sys.exit(bad)


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    main(sys.argv[1])
