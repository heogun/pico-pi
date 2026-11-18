#!/bin/sh
# Maintain pico8-hashes.txt, the signed list of known-good PICO-8 Raspberry
# Pi builds that consoles check before installing PICO-8 (verify_pico8 in
# lib.sh). Lexaloffle publishes no checksums, so add a version only from a
# copy you downloaded yourself from lexaloffle.com.
#
#   scripts/pico8-hashes.sh add pico-8_0.2.7_raspi.zip   (or an unpacked pico-8/)
#   scripts/pico8-hashes.sh sign                         (needs keys/ota-private.pem)
#
# Commit pico8-hashes.txt and pico8-hashes.txt.sig; consoles fetch them from
# the repository (main branch) and verify the signature with the OTA key.
set -eu
cd "$(dirname "$0")/.."
LIST=pico8-hashes.txt
case ${1:-} in
add)
	src=${2:?zip or folder}
	tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
	if [ -d "$src" ]; then cp -R "$src/." "$tmp/"; else unzip -q "$src" -d "$tmp"; fi
	dat=$(find "$tmp" -name pico8.dat | head -n 1)
	[ -n "$dat" ] || { echo "no pico8.dat in $src" >&2; exit 1; }
	d=$(dirname "$dat")
	v=$(grep -m1 -o 'PICO-8 v[0-9][0-9.a-z]*' "$d/pico-8_manual.txt"); v=${v#PICO-8 v}
	[ -n "$v" ] || { echo "cannot read the version from pico-8_manual.txt" >&2; exit 1; }
	if grep -q "^$v " "$LIST" 2>/dev/null; then echo "$v is already listed" >&2; exit 1; fi
	[ -f "$LIST" ] || printf '%s\n' "# Known-good PICO-8 Raspberry Pi builds: <version> <file> <sha256>" \
		"# Signed with the OTA key (pico8-hashes.txt.sig). See scripts/pico8-hashes.sh." > "$LIST"
	for f in pico8.dat pico8 pico8_dyn pico8_64 pico8_gpio; do
		[ -f "$d/$f" ] || continue
		h=$(if command -v sha256sum >/dev/null; then sha256sum "$d/$f"; else shasum -a 256 "$d/$f"; fi | cut -d' ' -f1)
		echo "$v $f $h" >> "$LIST"
	done
	echo "added PICO-8 $v; now run: $0 sign" ;;
sign)
	openssl dgst -sha256 -sign keys/ota-private.pem -out "$LIST.sig" "$LIST"
	openssl dgst -sha256 -verify keys/ota-public.pem -signature "$LIST.sig" "$LIST" ;;
*)
	sed -n '2,12s/^# \{0,1\}//p' "$0"; exit 2 ;;
esac
