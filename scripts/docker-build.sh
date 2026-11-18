#!/bin/sh
# Build a PICO8-OS image inside Docker. Buildroot sources, downloads and the
# build tree live in the "pico8os-work" volume (case-sensitive, fast); only the
# final image is copied back to ./dist.
set -eu
board=${1:?usage: $0 <rpi0|rpi2|rpi3|rpi4|rpi5|qemu>}
cd "$(dirname "$0")/.."
docker build -t pico8os-builder docker
docker run --rm -t \
	-v "$PWD":/src \
	-v pico8os-work:/work \
	-e BR2_DL_DIR=/work/dl \
	pico8os-builder \
	make -C /src BR_DIR=/work/buildroot OUT_ROOT=/work/output DIST_DIR=/src/dist "$board"
