# Sourced by post-image scripts: stage the initial content of the PICO8DATA
# partition in $BINARIES_DIR/datafiles (settings, carts, readme).
EXT=$(cd "$(dirname "$0")/../.." && pwd)
PROJ=$(cd "$EXT/.." && pwd)
STAGE="$BINARIES_DIR/datafiles"
rm -rf "$STAGE"
mkdir -p "$STAGE/carts" "$STAGE/screenshots" "$STAGE/pico8" "$STAGE/logs"
cp "$EXT/boot-files/pico8os.txt" "$STAGE/pico8os.txt"
cp "$EXT/boot-files/README.txt" "$STAGE/README.txt"
for d in carts screenshots pico8 logs; do : > "$STAGE/$d/.keep"; done
# Carts from <project>/carts are preinstalled.
if [ -d "$PROJ/carts" ]; then
	find "$PROJ/carts" -maxdepth 1 -type f \( -name '*.p8' -o -name '*.p8.png' \) \
		-exec cp {} "$STAGE/carts/" \;
fi
