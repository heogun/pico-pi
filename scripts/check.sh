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
	external/rootfs-overlay/usr/share/picopi/www/cgi-bin external/board scripts \
	-type f \( -name '*.sh' -o -perm -u+x \) ! -name '*.c' | sort)
for f in $scripts; do
	head -c 2 "$f" | grep -q '#!' || case $f in *.sh) ;; *) continue ;; esac
	sh -n "$f" || bad "syntax: $f"
done
if command -v shellcheck >/dev/null; then
	# shellcheck disable=SC2086
	shellcheck -S error -s sh $scripts || bad "shellcheck errors"
fi

note "== executable bits (the overlay keeps file modes)"
for f in external/rootfs-overlay/etc/init.d/* external/rootfs-overlay/usr/bin/* \
	external/rootfs-overlay/usr/sbin/* external/rootfs-overlay/usr/share/picopi/www/cgi-bin/*; do
	[ -x "$f" ] || bad "not executable: $f"
done

note "== Buildroot configs"
[ -f "$BR_DIR/Makefile" ] || make -s buildroot BR_DIR="$BR_DIR"
for b in rpi0 rpi2 rpi3 rpi4 rpi5 qemu; do
	case $b in qemu) fr="common qemu" ;; *) fr="common rpi-common $b" ;; esac
	if ! make -s BR_DIR="$BR_DIR" OUT_ROOT="$OUT" "$OUT/$b/.config" > "$OUT.$b.log" 2>&1; then
		bad "$b defconfig"; tail -n 20 "$OUT.$b.log"; continue
	fi
	miss=""
	for x in $fr; do
		for o in $(sed -n 's/^\(BR2_[A-Z0-9_]*\)=.*/\1/p' "external/fragments/$x.config"); do
			grep -q "^$o=" "$OUT/$b/.config" || miss="$miss $o"
		done
	done
	if [ -n "$miss" ]; then bad "$b dropped:$miss"; else note "$b ok"; fi
done

note "== settings cart Lua"
if command -v luajit >/dev/null; then
	tmp=$(mktemp)
	sed -n '/^__lua__$/,$p' external/rootfs-overlay/usr/share/picopi/cart/picopi.p8 | sed '1d' > "$tmp.lua"
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
