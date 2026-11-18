# shellcheck shell=bash
# (bash: uses arrays; sourced by the bash post-image scripts)
# Sourced by post-image scripts. Builds $BINARIES_DIR/bootfs, the content of
# the boot partition:
#   <firmware files>, config.txt, slot.txt ("os_prefix=a/")
#   a/<kernel> a/*.dtb a/overlays/ a/cmdline.txt     (slot A = this build)
# and writes the genimage config from $GENIMAGE_IN to $GENIMAGE_CFG.
# Inputs: KERNEL (file name), CMDLINE_IN (template with @ROOT@/@SLOT@),
#         ROOT_PREFIX (/dev/mmcblk0p or /dev/vda), FIRMWARE_DIR (or empty).
BOOTFS="$BINARIES_DIR/bootfs"
rm -rf "$BOOTFS"
mkdir -p "$BOOTFS/a"

if [ -n "${FIRMWARE_DIR:-}" ]; then
	for f in "$FIRMWARE_DIR"/*; do
		case $(basename "$f") in
			cmdline.txt) ;;
			overlays) cp -R "$f" "$BOOTFS/a/overlays" ;;
			*) cp -R "$f" "$BOOTFS/" ;;
		esac
	done
	# Overlays are only taken from ${os_prefix}overlays/ when a README exists
	# there; otherwise the firmware would look for shared /overlays/.
	mkdir -p "$BOOTFS/a/overlays"
	[ -f "$BOOTFS/a/overlays/README" ] || echo "PICO-PI slot overlays" > "$BOOTFS/a/overlays/README"
	cp "$BINARIES_DIR"/*.dtb "$BOOTFS/a/"
fi
cp "$BINARIES_DIR/$KERNEL" "$BOOTFS/a/$KERNEL"
sed -e "s#@ROOT@#${ROOT_PREFIX}2#" -e "s#@SLOT@#a#" "$CMDLINE_IN" > "$BOOTFS/a/cmdline.txt"
cp "$CMDLINE_IN" "$BINARIES_DIR/cmdline.txt.in"
echo "os_prefix=a/" > "$BOOTFS/slot.txt"

FILES=()
for i in "$BOOTFS"/*; do
	FILES+=( "${i#"$BINARIES_DIR"/}" )
done
BOOT_FILES=$(printf '\\t\\t\\t"%s",\\n' "${FILES[@]}")
sed "s|#BOOT_FILES#|${BOOT_FILES}|" "$GENIMAGE_IN" > "$GENIMAGE_CFG"
