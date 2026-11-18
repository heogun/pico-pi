# PICO-PI shared shell helpers (busybox ash compatible).
# Sourced by pico8-session, pico8-install, init scripts, and the host-side
# post-build script (install_zip only), so keep it POSIX sh.

PICO8_DIR=${PICO8_DIR:-/opt/pico8}
DATA=${DATA:-/data}
CONF_KEYS="LANGUAGE OTA_URL WEB_PASSWORD EXIT_ACTION PICO8_MODE PICO8_CART PICO8_ARGS VIDEO_DRIVER AUDIO_CARD KEYMAP WATCHDOG HOTKEY BLUETOOTH BT_PAIR_SECONDS WIFI_SSID WIFI_PSK WIFI_COUNTRY"

say() { printf '%s\n' "$*"; }

# Parse KEY=VALUE lines from /data/pico8os.txt. Only known keys are accepted
# and values are never evaluated as shell code.
load_config() {
	EXIT_ACTION=restart PICO8_MODE=splore PICO8_CART='' PICO8_ARGS=''
	VIDEO_DRIVER=kmsdrm AUDIO_CARD=auto KEYMAP=us WATCHDOG=on HOTKEY=on BLUETOOTH=on BT_PAIR_SECONDS=60
	WIFI_SSID='' WIFI_PSK='' WIFI_COUNTRY='' OTA_URL='' WEB_PASSWORD='' LANGUAGE=en
	f="$DATA/pico8os.txt"
	[ -r "$f" ] || return 0
	while IFS= read -r line || [ -n "$line" ]; do
		line=$(printf '%s' "$line" | tr -d '\r')
		case $line in ''|'#'*) continue ;; *=*) ;; *) continue ;; esac
		key=$(printf '%s' "${line%%=*}" | tr -d ' \t')
		case " $CONF_KEYS " in *" $key "*) ;; *) continue ;; esac
		val=$(printf '%s' "${line#*=}" | sed 's/^[[:space:]]*//')
		case $val in
			\"*) val=${val#\"}; val=${val%%\"*} ;;
			\'*) val=${val#\'}; val=${val%%\'*} ;;
			*) val=${val%%[ 	]#*}; val=$(printf '%s' "$val" | sed 's/[[:space:]]*$//') ;;
		esac
		eval "$key=\$val"
	done < "$f"
}

zip_sum() { sha256sum "$1" | cut -d' ' -f1; }

# Newest official Raspberry Pi build zip on the data partition.
find_zip() {
	ls -1 "$DATA"/pico-8*raspi*.zip 2>/dev/null | sort | tail -n 1
}

# A "pico-8" folder the user unzipped onto the data partition themselves.
find_folder() {
	for d in "$DATA/pico-8" "$DATA/pico8-install"; do
		[ -f "$d/pico8.dat" ] && { echo "$d"; return 0; }
	done
	return 1
}

is_installed() { [ -f "$PICO8_DIR/pico8.dat" ]; }

# Fingerprint of a source (zip file or folder) to skip reinstalling it.
source_sum() {
	if [ -d "$1" ]; then
		ls -l "$1"/pico8* 2>/dev/null | sha256sum | cut -d' ' -f1
	else
		zip_sum "$1"
	fi
}

# install_pico8 SRC DEST: copy PICO-8 from a pico-8_*_raspi.zip or an
# unpacked folder into DEST, atomically.
install_pico8() {
	src=$1 dest=$2
	sum=$(source_sum "$src")
	if [ -f "$dest/pico8.dat" ] && [ "$(cat "$dest/.source" 2>/dev/null)" = "$sum" ]; then
		return 0
	fi
	tmp="$dest.new"
	rm -rf "$tmp" && mkdir -p "$tmp"
	if [ -d "$src" ]; then
		cp -R "$src/." "$tmp/" || { rm -rf "$tmp"; say "ERROR: cannot copy $src"; return 1; }
	elif ! unzip -q -o "$src" -d "$tmp"; then
		rm -rf "$tmp"; say "ERROR: cannot unzip $src"; return 1
	fi
	dat=$(find "$tmp" -name pico8.dat | head -n 1)
	if [ -z "$dat" ]; then
		rm -rf "$tmp"; say "ERROR: pico8.dat not found in $src (need the Raspberry Pi build)"; return 1
	fi
	top=$(dirname "$dat")
	rm -rf "$dest.old"
	[ -e "$dest" ] && mv "$dest" "$dest.old"
	mv "$top" "$dest"
	rm -rf "$tmp" "$dest.old"
	for b in pico8 pico8_dyn pico8_64 pico8_gpio; do
		[ -f "$dest/$b" ] && chmod 755 "$dest/$b"
	done
	printf '%s\n' "$sum" > "$dest/.source"
	sync
}

# Copy a PICO-8 zip from the root of any USB storage device to /data.
scan_usb() {
	mkdir -p /tmp/usb
	for dev in /dev/sd[a-z][0-9]* /dev/sd[a-z]; do
		[ -b "$dev" ] || continue
		mount -o ro "$dev" /tmp/usb 2>/dev/null || continue
		z=$(ls -1 /tmp/usb/pico-8*raspi*.zip 2>/dev/null | sort | tail -n 1)
		if [ -n "$z" ]; then
			say "Copying $(basename "$z") from $dev ..."
			cp "$z" "$DATA/" && sync
			umount /tmp/usb
			return 0
		fi
		umount /tmp/usb
	done
	return 1
}

# ---- system helpers (web UI, settings cart, OTA) ----

RUN=/run/picopi

# Partition prefix of the system disk: /dev/mmcblk0p (Pi) or /dev/vda (QEMU).
disk_prefix() {
	if [ -b /dev/mmcblk0 ]; then echo /dev/mmcblk0p
	elif [ -b /dev/vda ]; then echo /dev/vda
	fi
}

# Running system slot (a|b), from the kernel command line.
current_slot() {
	for w in $(cat /proc/cmdline); do
		case $w in picopi.slot=*) echo "${w#picopi.slot=}"; return ;; esac
	done
	echo a
}

other_slot() { [ "$1" = a ] && echo b || echo a; }
slot_part() { [ "$1" = a ] && echo "$(disk_prefix)2" || echo "$(disk_prefix)3"; }

os_version() { cat /etc/picopi/version 2>/dev/null || echo unknown; }
os_board() { cat /etc/picopi/board 2>/dev/null || echo unknown; }

# set_conf KEY VALUE: change one setting in pico8os.txt in place, keeping
# comments and order (appends the key if missing). Values are single-line.
# Values with spaces, '#' or quotes are quoted with whichever quote they
# do not contain (Wi-Fi passwords may contain either); a value holding both
# kinds cannot be written and is rejected.
set_conf() {
	key=$1 val=$(printf '%s' "$2" | tr -d '\r\n')
	case " $CONF_KEYS " in *" $key "*) ;; *) return 1 ;; esac
	f="$DATA/pico8os.txt"
	[ -f "$f" ] || : > "$f"
	case $val in
		*\"*\'*|*\'*\"*) return 2 ;;
		*\"*) line="$key='$val'" ;;
		*[" 	#'"]*) line="$key=\"$val\"" ;;
		*) line="$key=$val" ;;
	esac
	tmp="$f.tmp"
	awk -v k="$key" -v l="$line" '
		BEGIN { done = 0 }
		{ s = $0; sub(/\r$/, "", s); t = s; sub(/^[ \t]+/, "", t)
		  if (!done && index(t, k "=") == 1) { print l; done = 1; next }
		  if (!done && match(t, "^" k "[ \t]*=")) { print l; done = 1; next }
		  print }
		END { if (!done) print l }' "$f" > "$tmp" && mv "$tmp" "$f"
	sync
}

# JSON string escaping for the web API.
json_str() {
	printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' | tr -d '\r' | awk 'NR>1{printf "\\n"} {printf "%s", $0}')"
}

current_ip() {
	ip -4 -o addr show scope global 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4; exit}'
}

# Web UI password: WEB_PASSWORD from pico8os.txt, else one generated on
# first boot and kept on the state partition.
web_password() {
	if [ -n "$WEB_PASSWORD" ]; then echo "$WEB_PASSWORD"; return; fi
	pw=/state/web-password
	if [ ! -s "$pw" ]; then
		tr -dc 'a-km-z2-9' < /dev/urandom 2>/dev/null | head -c 8 > "$pw.tmp" && mv "$pw.tmp" "$pw"
		sync
	fi
	cat "$pw"
}

# Restart PICO-8 (init respawns pico8-session). Optional: run CART next.
restart_pico8() {
	mkdir -p "$RUN"
	[ -n "${1:-}" ] && echo "$1" > "$RUN/next-cart"
	killall pico8 pico8_dyn pico8_64 pico8_gpio 2>/dev/null
	# A frozen PICO-8 may ignore SIGTERM.
	( sleep 2; killall -9 pico8 pico8_dyn pico8_64 pico8_gpio 2>/dev/null ) &
	return 0
}
