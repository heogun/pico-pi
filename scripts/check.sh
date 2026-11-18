#!/bin/sh
# Fast checks without a full build (CI "check" workflow, or locally):
#   1. shell syntax of every device/build script (sh -n, plus shellcheck
#      errors when shellcheck is installed)
#   2. Buildroot resolves every option of every board (defconfig only; an
#      option dropped by an unmet dependency is an error)
#   3. settings cart Lua syntax (luajit), web translation table complete (node)
#
#   scripts/check.sh [BR_DIR] [OUT_DIR]
set -eu
cd "$(dirname "$0")/.."
BR_DIR=${1:-$PWD/buildroot}
OUT=${2:-$PWD/output/check}
fail=0
note() { printf '%s\n' "$*"; }
bad() { printf 'FAIL: %s\n' "$*"; fail=1; }

note "== shell scripts"
scripts=$(find external/rootfs-overlay/etc/init.d external/rootfs-overlay/usr/bin \
	external/rootfs-overlay/usr/sbin external/rootfs-overlay/usr/lib \
	external/rootfs-overlay/usr/share/pico8os/www/cgi-bin external/board scripts \
	-type f \( -name '*.sh' -o -perm -u+x \) ! -name '*.c' | sort)
# Interpreter per file: its shebang, or "# shellcheck shell=bash" for
# sourced bash fragments; everything else must be POSIX sh (busybox ash on
# the device), so check it with the system sh (dash on Debian/Ubuntu).
shell_of() {
	if head -n 1 "$1" | grep -q '^#!.*bash' || grep -q '^# shellcheck shell=bash' "$1"; then
		echo bash
	else
		echo sh
	fi
}
for f in $scripts; do
	case $f in
		*.sh) ;;
		*) head -n 1 "$f" | grep -Eq '^#!.*[/ ](ba)?sh([[:space:]]|$)' || continue ;;
	esac
	sh_=$(shell_of "$f")
	$sh_ -n "$f" || bad "syntax ($sh_): $f"
	if command -v shellcheck >/dev/null; then
		shellcheck -S error -s "$sh_" "$f" || bad "shellcheck: $f"
	fi
done

note "== executable bits (the overlay keeps file modes)"
for f in external/rootfs-overlay/etc/init.d/* external/rootfs-overlay/usr/bin/* \
	external/rootfs-overlay/usr/sbin/* external/rootfs-overlay/usr/share/pico8os/www/cgi-bin/*; do
	[ -x "$f" ] || bad "not executable: $f"
done

note "== Buildroot configs"
[ -f "$BR_DIR/Makefile" ] || make -s buildroot BR_DIR="$BR_DIR"
mkdir -p "$OUT"
for b in rpi0 rpi2 rpi3 rpi4 rpi5 qemu; do
	case $b in qemu) fr="common qemu" ;; *) fr="common rpi-common $b" ;; esac
	if ! make -s BR_DIR="$BR_DIR" OUT_ROOT="$OUT" "$OUT/$b/.config" > "$OUT/$b.log" 2>&1; then
		bad "$b defconfig"; tail -n 20 "$OUT/$b.log"; continue
	fi
	miss=""
	for x in $fr; do
		for o in $(sed -n 's/^\(BR2_[A-Z0-9_]*\)=.*/\1/p' "external/fragments/$x.config"); do
			grep -q "^$o=" "$OUT/$b/.config" || miss="$miss $o"
		done
	done
	if [ -n "$miss" ]; then bad "$b dropped:$miss"; else note "$b ok"; fi
done

note "== busybox applets the scripts need"
# Buildroot's default busybox config plus board/common/busybox.fragment.
bbfrag=external/board/common/busybox.fragment
for a in STAT FEATURE_STAT_FORMAT TIMEOUT FLOCK MKTEMP OD DD; do
	if grep -q "^CONFIG_$a=y" "$bbfrag"; then continue; fi
	if grep -q "^# CONFIG_$a is not set" "$bbfrag" ||
	   ! grep -q "^CONFIG_$a=y" "$BR_DIR/package/busybox/busybox.config"; then
		bad "busybox applet/feature $a is not enabled"
	fi
done

note "== settings cart Lua"
if command -v luajit >/dev/null; then
	tmp=$(mktemp)
	sed -n '/^__lua__$/,$p' external/rootfs-overlay/usr/share/pico8os/cart/pico8os.p8 | sed '1d' > "$tmp.lua"
	luajit -b "$tmp.lua" "$tmp.out" || bad "cart Lua syntax"
	rm -f "$tmp" "$tmp.lua" "$tmp.out"
else
	note "(luajit not installed, skipped)"
fi

note "== web translations"
if command -v node >/dev/null; then
	node scripts/check-i18n.js || bad "web translations"
else
	note "(node not installed, skipped)"
fi

[ $fail = 0 ] && note "all checks passed"
exit $fail
