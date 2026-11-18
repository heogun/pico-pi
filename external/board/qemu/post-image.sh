#!/bin/bash
# PICO-PI post-image for QEMU virt: same layout and OTA bundle as the Pi
# images; the kernel and cmdline of the active slot are read by run-qemu.sh.
set -euo pipefail
BOARD_DIR=$(cd "$(dirname "$0")" && pwd)
PICOPI_BOARD=${2:-qemu}
. "$BOARD_DIR/../common/stage-data-files.sh"

KERNEL=zImage
CMDLINE_IN="$BOARD_DIR/cmdline.txt"
ROOT_PREFIX=/dev/vda
FIRMWARE_DIR=""
GENIMAGE_IN="$BOARD_DIR/genimage.cfg.in"
GENIMAGE_CFG="$BINARIES_DIR/genimage.cfg"
. "$BOARD_DIR/../common/stage-boot.sh"
. "$BOARD_DIR/../common/run-genimage.sh"
. "$BOARD_DIR/../common/make-update.sh"
