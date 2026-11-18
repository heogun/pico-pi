#!/bin/sh
# Boot the PICO-PI QEMU image (qemu-system-arm, "virt" machine).
#   scripts/run-qemu.sh [--zip pico-8_x.y.z_raspi.zip] [--fresh]
# --zip   copy the PICO-8 Raspberry Pi zip onto the PICO8DATA partition
# --fresh start again from dist/picopi-qemu.img
#
# Like the Pi firmware, this reads slot.txt from the boot partition and boots
# that slot's kernel and cmdline.txt, so OTA updates and rollbacks work in
# QEMU too. Needs mtools (port install mtools / apt install mtools).
# Web UI: http://localhost:8080 (forwarded). Serial console is on this
# terminal (login: root); quit with Ctrl-A X.
set -eu
cd "$(dirname "$0")/.."
BASE=dist/picopi-qemu.img
DISK=dist/picopi-qemu-run.img
WORK=dist/.qemu
zip=''
while [ $# -gt 0 ]; do
	case $1 in
		--zip) zip=$2; shift 2 ;;
		--fresh) rm -f "$DISK"; shift ;;
		*) echo "unknown option: $1" >&2; exit 1 ;;
	esac
done
[ -f "$BASE" ] || { echo "build first: make qemu (or make docker-qemu)" >&2; exit 1; }
command -v mcopy >/dev/null || { echo "needs mtools (port install mtools / apt install mtools)" >&2; exit 1; }
[ -f "$DISK" ] || cp "$BASE" "$DISK"

# Byte offset of partition N (1-based, logical partitions 5+) from MBR/EBRs.
part_offset() {
	python3 -I - "$DISK" "$1" <<'EOF'
import struct, sys
img, want = sys.argv[1], int(sys.argv[2])
f = open(img, 'rb')
def entries(lba):
    f.seek(lba * 512); s = f.read(512)
    return [struct.unpack('<B3xB3xII', s[446 + 16*i:462 + 16*i]) for i in range(4)]
ext = None
for i, (_, typ, start, size) in enumerate(entries(0), 1):
    if typ in (0x05, 0x0f): ext = start
    elif i == want: print(start * 512); sys.exit(0)
n, ebr = 5, ext
while ebr is not None:
    e = entries(ebr)
    if n == want: print((ebr + e[0][2]) * 512); sys.exit(0)
    if e[1][1] == 0: break
    ebr, n = ext + e[1][2], n + 1
sys.exit("partition %d not found" % want)
EOF
}

BOOT_OFF=$(part_offset 1)
DATA_OFF=$(part_offset 5)

if [ -n "$zip" ]; then
	mcopy -o -i "$DISK@@$DATA_OFF" "$zip" ::/
	echo "copied $(basename "$zip") to PICO8DATA"
fi

case $(uname -s) in
	Darwin) AUDIO=coreaudio; DISPLAY_OPT="-display cocoa" ;;
	*) AUDIO=pa; DISPLAY_OPT="-display gtk" ;;
esac

# QEMU keeps -kernel/-append across a guest reboot, which would boot the old
# slot after an OTA install (and make the update look failed). So reboots
# exit QEMU (-no-reboot) and this loop re-reads slot.txt, like the firmware.
while :; do
	slot=$(mcopy -i "$DISK@@$BOOT_OFF" ::slot.txt - | sed -n 's#^os_prefix=\([ab]\)/.*#\1#p')
	slot=${slot:-a}
	rm -rf "$WORK" && mkdir -p "$WORK"
	mcopy -i "$DISK@@$BOOT_OFF" "::$slot/zImage" "$WORK/zImage"
	mcopy -i "$DISK@@$BOOT_OFF" "::$slot/cmdline.txt" "$WORK/cmdline.txt"
	echo "booting slot $slot: $(cat "$WORK/cmdline.txt")"

	qemu-system-arm \
		-M virt -cpu cortex-a15 -smp 2 -m 1024 -no-reboot \
		-kernel "$WORK/zImage" \
		-append "$(cat "$WORK/cmdline.txt")" \
		-drive if=none,file="$DISK",format=raw,id=hd0 -device virtio-blk-device,drive=hd0 \
		-device virtio-gpu-device \
		-device virtio-keyboard-device -device virtio-tablet-device \
		-netdev user,id=net0,hostfwd=tcp::8080-:80 -device virtio-net-device,netdev=net0 \
		-audiodev "$AUDIO",id=snd0 -device virtio-sound-device,audiodev=snd0 \
		$DISPLAY_OPT -serial mon:stdio || exit $?

	printf '\nPICO-PI stopped (reboot or power off). Boot again? [Y/n] (5 s) '
	if read -r -t 5 ans && [ "$ans" = n ]; then exit 0; fi
	echo
done
