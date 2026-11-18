#!/bin/bash
# PICO-PI post-image for Raspberry Pi: boot partition with A/B slots,
# data + state partitions, sdcard.img and the signed OTA bundle.
# $1 = BINARIES_DIR, $2 = board name (BR2_ROOTFS_POST_SCRIPT_ARGS)
set -euo pipefail
BOARD_DIR=$(cd "$(dirname "$0")" && pwd)
PICOPI_BOARD=${2:-}
. "$BOARD_DIR/../common/stage-data-files.sh"

KERNEL=$(sed -n 's/^kernel=//p' "$BINARIES_DIR/rpi-firmware/config.txt")
CMDLINE_IN="$BINARIES_DIR/rpi-firmware/cmdline.txt"
ROOT_PREFIX=/dev/mmcblk0p
FIRMWARE_DIR="$BINARIES_DIR/rpi-firmware"
GENIMAGE_IN="$BOARD_DIR/genimage.cfg.in"
GENIMAGE_CFG="$BINARIES_DIR/genimage.cfg"
. "$BOARD_DIR/../common/stage-boot.sh"
. "$BOARD_DIR/../common/run-genimage.sh"
. "$BOARD_DIR/../common/make-update.sh"
