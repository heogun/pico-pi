# Sourced by post-image scripts after genimage: build the signed OTA bundle
#   $BINARIES_DIR/pico8os-<board>-<version>.pico8os-update
# = tar of: manifest, manifest.sig, cmdline.txt.in, boot.tar.gz, rootfs.ext4.gz
# The manifest carries sha256 of every payload, and only the manifest is
# signed (ECDSA P-256 / SHA-256), so the device verifies the signature first,
# then private copies of the small payloads, and finally reads the written
# slot back and compares it with rootfs_raw_sha256 before switching to it.
#
# Without keys/ota-private.pem (CI build jobs) the bundle is left unsigned
# (no manifest.sig); scripts/sign-update.sh signs it in a separate step that
# alone holds the key.
: "${PICO8OS_BOARD:?board name missing (BR2_ROOTFS_POST_SCRIPT_ARGS)}"
: "${PICO8OS_VERSION:?PICO8OS_VERSION not set (build through the top-level Makefile)}"
KEY="$PROJ/keys/ota-private.pem"

UPD="$BINARIES_DIR/update"
rm -rf "$UPD" && mkdir -p "$UPD"
gzip -9n -c "$BINARIES_DIR/rootfs.ext4" > "$UPD/rootfs.ext4.gz"
tar -C "$BINARIES_DIR/bootfs/a" --exclude=./cmdline.txt --owner=0 --group=0 --numeric-owner \
	-czf "$UPD/boot.tar.gz" .
cp "$BINARIES_DIR/cmdline.txt.in" "$UPD/cmdline.txt.in"
sum() { sha256sum "$1" | cut -d' ' -f1; }
# -L: images/rootfs.ext4 is a symlink to rootfs.ext2
rootfs_size=$(stat -L -c %s "$BINARIES_DIR/rootfs.ext4")
case $rootfs_size in ''|*[!0-9]*) echo "bad rootfs size: $rootfs_size" >&2; exit 1 ;; esac
cat > "$UPD/manifest" <<MANIFEST
format=1
board=$PICO8OS_BOARD
version=$PICO8OS_VERSION
rootfs_size=$rootfs_size
rootfs_sha256=$(sum "$UPD/rootfs.ext4.gz")
rootfs_raw_sha256=$(sha256sum < "$BINARIES_DIR/rootfs.ext4" | cut -d' ' -f1)
boot_sha256=$(sum "$UPD/boot.tar.gz")
cmdline_sha256=$(sum "$UPD/cmdline.txt.in")
MANIFEST
BUNDLE="$BINARIES_DIR/pico8os-$PICO8OS_BOARD-$PICO8OS_VERSION.pico8os-update"
rm -f "$BINARIES_DIR"/*.pico8os-update
tar -C "$UPD" --owner=0 --group=0 --numeric-owner -cf "$BUNDLE" \
	manifest cmdline.txt.in boot.tar.gz rootfs.ext4.gz
if [ -f "$KEY" ]; then
	"$PROJ/scripts/sign-update.sh" "$BUNDLE" "$KEY"
	echo ">>> PICO8-OS update bundle: $BUNDLE"
else
	echo ">>> PICO8-OS update bundle (UNSIGNED, run scripts/sign-update.sh): $BUNDLE"
fi
