#!/bin/sh
# PICO8-OS post-build: runs on the build host with TARGET_DIR set.
set -eu
EXT=$(cd "$(dirname "$0")/../.." && pwd)
PROJ=$(cd "$EXT/.." && pwd)
INITTAB="$TARGET_DIR/etc/inittab"
BOARD=${2:?board name missing (BR2_ROOTFS_POST_SCRIPT_ARGS)}
: "${PICO8OS_VERSION:?PICO8OS_VERSION not set (build through the top-level Makefile)}"

# Identity used by OTA updates (board must match, versions compare as text)
# and the OTA signing key (public half only).
mkdir -p "$TARGET_DIR/etc/pico8os"
echo "$BOARD" > "$TARGET_DIR/etc/pico8os/board"
echo "$PICO8OS_VERSION" > "$TARGET_DIR/etc/pico8os/version"
[ -f "$PROJ/keys/ota-public.pem" ] || { echo "missing keys/ota-public.pem (run: make keys)" >&2; exit 1; }
cp "$PROJ/keys/ota-public.pem" "$TARGET_DIR/etc/pico8os/ota-public.pem"

# tty1 runs the PICO-8 session instead of a login prompt. Root has no
# password login and there is no getty: the serial console gets a root shell
# only with DEBUG=on (pico8os-debugsh).
sed -i -e '/^tty1::/d' -e '/pico8os-debugsh/d' -e '/rc\.late/d' "$INITTAB"
sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/usr/bin/pico8-session\
console::respawn:/usr/sbin/pico8os-debugsh' "$INITTAB"

# Two-phase boot: rcS runs only S00-S20 (data mount, OTA boot check, udev,
# watchdog, hotkey); everything else starts from rc.late in the background,
# while PICO-8 is already starting.
mkdir -p "$TARGET_DIR/etc/init.d/late"
for f in "$TARGET_DIR"/etc/init.d/S??*; do
	[ -e "$f" ] || continue
	n=$(basename "$f" | cut -c2-3)
	case $n in [0-9][0-9]) [ "$n" -gt 20 ] && mv "$f" "$TARGET_DIR/etc/init.d/late/" ;; esac
done
awk '
	/^::sysinit:\/etc\/init.d\/rcS/ { print; print "::once:/etc/init.d/rc.late start"; next }
	/^::shutdown:/ && !done { print "::shutdown:/etc/init.d/rc.late stop"; done = 1 }
	{ print }' "$INITTAB" > "$INITTAB.new" && mv "$INITTAB.new" "$INITTAB"

# dnsmasq runs only in Wi-Fi setup (AP) mode, started by pico8os-wifi; never
# as a system-wide DNS/DHCP service.
rm -f "$TARGET_DIR/etc/init.d/S80dnsmasq" "$TARGET_DIR/etc/init.d/late/S80dnsmasq"
# lighttpd runs only with PICO8-OS's own config (pico8os-web), never the
# package's stock service and config.
rm -f "$TARGET_DIR/etc/init.d/S50lighttpd" "$TARGET_DIR/etc/init.d/late/S50lighttpd"

# tmpfs mounts: no setuid programs or device nodes (writable places only)
sed -i -E '/^tmpfs[[:space:]]/ s/([[:space:]]tmpfs[[:space:]]+)([^[:space:]]+)/\1\2,nosuid,nodev/' "$TARGET_DIR/etc/fstab"

# Signed list of known-good PICO-8 builds (see scripts/pico8-hashes.sh).
mkdir -p "$TARGET_DIR/usr/share/pico8os"
cp "$PROJ/pico8-hashes.txt" "$PROJ/pico8-hashes.txt.sig" "$TARGET_DIR/usr/share/pico8os/"

mkdir -p "$TARGET_DIR/data" "$TARGET_DIR/state" "$TARGET_DIR/opt" "$TARGET_DIR/var/lib" "$TARGET_DIR/boot"

# Screenshots are served by the API (login required), not from the web root.
rm -f "$TARGET_DIR/usr/share/pico8os/www/shots"

# Bluetooth pairings must survive reboots but the root is read-only:
# keep them on the ext4 state partition.
rm -rf "$TARGET_DIR/var/lib/bluetooth"
ln -sfn /state/bluetooth "$TARGET_DIR/var/lib/bluetooth"

# Optional: bake PICO-8 from <project>/pico8/ (zip or unpacked pico-8/) into the image.
# The result contains Lexaloffle's software -> for personal use only.
src=$(ls -1 "$PROJ"/pico8/pico-8*raspi*.zip 2>/dev/null | sort | tail -n 1 || true)
[ -f "$PROJ/pico8/pico-8/pico8.dat" ] && src="$PROJ/pico8/pico-8"
if [ -n "$src" ]; then
	echo ">>> PICO8-OS: baking $(basename "$src") into /opt/pico8"
	DATA=/nonexistent . "$TARGET_DIR/usr/lib/pico8os/lib.sh"
	# Same check as on the console, against the repository's signed list.
	HASH_LISTS="$PROJ/pico8-hashes.txt" HASH_PUBKEY="$PROJ/keys/ota-public.pem"
	case $BOARD in rpi5) PICO8_ARCH=aarch64 ;; *) PICO8_ARCH=armv7l ;; esac
	PICO8_VERIFY=${PICO8_VERIFY:-strict}
	install_pico8 "$src" "$TARGET_DIR/opt/pico8" || {
		echo "PICO8-OS: not baking $(basename "$src") (see above; PICO8_VERIFY=warn make ... to allow an unlisted version)" >&2
		exit 1
	}
else
	# Never leave a previously baked copy behind.
	rm -rf "$TARGET_DIR/opt/pico8"
fi

# Report how the display driver ended up (linux-fastboot.fragment asks for
# built-in; kconfig keeps a module if a dependency cannot be built in).
kcfg=$(ls -d "$BUILD_DIR"/linux-*/.config 2>/dev/null | head -n 1)
if [ -n "$kcfg" ]; then
	echo ">>> PICO8-OS kernel: $(grep -E '^CONFIG_DRM_VC4=' "$kcfg" || echo 'CONFIG_DRM_VC4 not set')"
fi
