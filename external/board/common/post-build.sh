#!/bin/sh
# PICO-PI post-build: runs on the build host with TARGET_DIR set.
set -eu
EXT=$(cd "$(dirname "$0")/../.." && pwd)
PROJ=$(cd "$EXT/.." && pwd)
INITTAB="$TARGET_DIR/etc/inittab"
BOARD=${2:?board name missing (BR2_ROOTFS_POST_SCRIPT_ARGS)}
: "${PICOPI_VERSION:?PICOPI_VERSION not set (build through the top-level Makefile)}"

# Identity used by OTA updates (board must match, versions compare as text)
# and the OTA signing key (public half only).
mkdir -p "$TARGET_DIR/etc/picopi"
echo "$BOARD" > "$TARGET_DIR/etc/picopi/board"
echo "$PICOPI_VERSION" > "$TARGET_DIR/etc/picopi/version"
[ -f "$PROJ/keys/ota-public.pem" ] || { echo "missing keys/ota-public.pem (run: make keys)" >&2; exit 1; }
cp "$PROJ/keys/ota-public.pem" "$TARGET_DIR/etc/picopi/ota-public.pem"

# tty1 runs the PICO-8 session instead of a login prompt.
sed -i '/^tty1::/d' "$INITTAB"
sed -i '/GENERIC_SERIAL/a\
tty1::respawn:/usr/bin/pico8-session' "$INITTAB"

mkdir -p "$TARGET_DIR/data" "$TARGET_DIR/state" "$TARGET_DIR/opt" "$TARGET_DIR/var/lib" "$TARGET_DIR/boot"

# Web UI serves screenshots straight from the data partition.
ln -sfn /data/screenshots "$TARGET_DIR/usr/share/picopi/www/shots"

# Bluetooth pairings must survive reboots but the root is read-only:
# keep them on the ext4 state partition.
rm -rf "$TARGET_DIR/var/lib/bluetooth"
ln -sfn /state/bluetooth "$TARGET_DIR/var/lib/bluetooth"

# Optional: bake PICO-8 from <project>/pico8/ (zip or unpacked pico-8/) into the image.
# The result contains Lexaloffle's software -> for personal use only.
src=$(ls -1 "$PROJ"/pico8/pico-8*raspi*.zip 2>/dev/null | sort | tail -n 1 || true)
[ -f "$PROJ/pico8/pico-8/pico8.dat" ] && src="$PROJ/pico8/pico-8"
if [ -n "$src" ]; then
	echo ">>> PICO-PI: baking $(basename "$src") into /opt/pico8"
	DATA=/nonexistent . "$TARGET_DIR/usr/lib/pico8os/lib.sh"
	install_pico8 "$src" "$TARGET_DIR/opt/pico8"
else
	# Never leave a previously baked copy behind.
	rm -rf "$TARGET_DIR/opt/pico8"
fi
