# Sourced by post-image scripts: run genimage with config $GENIMAGE_CFG.
GENIMAGE_TMP="$BUILD_DIR/genimage.tmp"
ROOTPATH_TMP=$(mktemp -d)
trap 'rm -rf "$ROOTPATH_TMP"' EXIT
rm -rf "$GENIMAGE_TMP"
genimage \
	--rootpath "$ROOTPATH_TMP" \
	--tmppath "$GENIMAGE_TMP" \
	--inputpath "$BINARIES_DIR" \
	--outputpath "$BINARIES_DIR" \
	--config "$GENIMAGE_CFG"
