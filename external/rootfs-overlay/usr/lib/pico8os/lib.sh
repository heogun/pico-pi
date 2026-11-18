# PICO8-OS shared shell helpers (busybox ash compatible).
# Sourced by pico8-session, pico8-install, init scripts, and the host-side
# post-build script (install_zip only), so keep it POSIX sh.

PICO8_DIR=${PICO8_DIR:-/opt/pico8}
DATA=${DATA:-/data}
CONF_KEYS="DEBUG CPU_GOVERNOR PICO8_VERIFY LANGUAGE OTA_URL WEB_PASSWORD EXIT_ACTION PICO8_MODE PICO8_CART PICO8_ARGS VIDEO_DRIVER AUDIO_CARD KEYMAP WATCHDOG HOTKEY BLUETOOTH BT_PAIR_SECONDS WIFI_SSID WIFI_PSK WIFI_COUNTRY"

say() { printf '%s\n' "$*"; }

# Parse KEY=VALUE lines from /data/pico8os.txt. Only known keys are accepted
# and values are never evaluated as shell code.
load_config() {
	EXIT_ACTION=restart PICO8_MODE=splore PICO8_CART='' PICO8_ARGS=''
	VIDEO_DRIVER=kmsdrm AUDIO_CARD=auto KEYMAP=us WATCHDOG=on HOTKEY=on BLUETOOTH=on BT_PAIR_SECONDS=60
	WIFI_SSID='' WIFI_PSK='' WIFI_COUNTRY='' OTA_URL='' WEB_PASSWORD='' LANGUAGE=en
	DEBUG=off CPU_GOVERNOR=performance PICO8_VERIFY=strict
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
# unpacked folder into DEST, atomically, after verify_pico8.
# Returns 0 installed, 1 unusable source, 3 unknown version (strict),
# 4 mismatch / wrong CPU (always refused).
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
	# Check the package before it replaces anything (see verify_pico8).
	result=$(verify_pico8 "$top"); vrc=$?
	PICO8_VERIFY_RESULT=$result
	if [ $vrc = 2 ] || { [ $vrc = 1 ] && [ "${PICO8_VERIFY:-strict}" != warn ]; }; then
		rm -rf "$tmp"
		case $result in
			mismatch*) say "REFUSED: PICO-8 $(basename "$src") does not match the known-good hashes (damaged or modified)." ;;
			invalid*) say "REFUSED: $(basename "$src") is not a Raspberry Pi PICO-8 for this console ($(uname -m))." ;;
			*) say "REFUSED: PICO-8 version ${result#* } is not on the verified list yet (PICO8_VERIFY=warn allows it)." ;;
		esac
		[ $vrc = 1 ] && return 3
		return 4
	fi
	rm -rf "$dest.old"
	[ -e "$dest" ] && mv "$dest" "$dest.old"
	mv "$top" "$dest"
	rm -rf "$tmp" "$dest.old"
	for b in pico8 pico8_dyn pico8_64 pico8_gpio; do
		[ -f "$dest/$b" ] && chmod 755 "$dest/$b"
	done
	printf '%s\n' "$sum" > "$dest/.source"
	printf '%s\n' "$result" > "$dest/.verify"     # "ok 0.2.7" / "unknown 0.2.8"
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

RUN=/run/pico8os

# Partition prefix of the system disk: /dev/mmcblk0p (Pi) or /dev/vda (QEMU).
disk_prefix() {
	if [ -b /dev/mmcblk0 ]; then echo /dev/mmcblk0p
	elif [ -b /dev/vda ]; then echo /dev/vda
	fi
}

# Running system slot (a|b), from the kernel command line.
current_slot() {
	for w in $(cat /proc/cmdline); do
		case $w in pico8os.slot=*) echo "${w#pico8os.slot=}"; return ;; esac
	done
	echo a
}

other_slot() { [ "$1" = a ] && echo b || echo a; }
slot_part() { [ "$1" = a ] && echo "$(disk_prefix)2" || echo "$(disk_prefix)3"; }

os_version() { cat /etc/pico8os/version 2>/dev/null || echo unknown; }
os_board() { cat /etc/pico8os/board 2>/dev/null || echo unknown; }

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

# WPA2 password of the Wi-Fi setup access point, generated once and kept
# on the state partition (shown in the settings cart and wifi-setup.txt).
ap_password() {
	pw=/state/ap-password
	if [ ! -s "$pw" ]; then
		tr -dc 'a-km-z2-9' < /dev/urandom 2>/dev/null | head -c 10 > "$pw.tmp" && mv "$pw.tmp" "$pw"
		chmod 600 "$pw"; sync
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

# ---- privileged requests (web UI runs as the unprivileged www user) ----
# priv CMD [ARG...]: ask pico8os-agent (root) to run one whitelisted action
# (see priv_run in pico8os-agent). Prints its output, returns its exit code;
# 124 if the agent does not answer within PRIV_TIMEOUT seconds (default 30).
# The spool directory is root:www 0730: www can drop requests but cannot list
# or read other requests; answers are fetched by their unique name.
PRIV_DIR="$RUN/priv"
priv() {
	id="$$.$(date +%s).$(od -An -N4 -tx4 /dev/urandom | tr -d ' ')"
	printf '%s\n' "$@" > "$PRIV_DIR/$id.tmp" || return 125
	mv "$PRIV_DIR/$id.tmp" "$PRIV_DIR/$id.req" || return 125
	i=0 max=$(( ${PRIV_TIMEOUT:-30} * 5 ))
	while [ ! -f "$PRIV_DIR/$id.done" ]; do
		i=$((i + 1)); [ $i -gt $max ] && return 124
		sleep 0.2
	done
	cat "$PRIV_DIR/$id.out" 2>/dev/null
	rc=$(cat "$PRIV_DIR/$id.done")
	rm -f "$PRIV_DIR/$id.out" "$PRIV_DIR/$id.done"
	return "${rc:-1}"
}

# ---- PICO-8 package verification ----
# Lexaloffle publishes no checksums, so PICO8-OS keeps its own list of
# known-good builds: pico8-hashes.txt ("<version> <file> <sha256>"), signed
# with the OTA key. A copy ships in the image; a newer one is fetched from
# PICO8_HASHES_URL and used only if its signature verifies.
PICO8_HASHES_URL=${PICO8_HASHES_URL:-https://raw.githubusercontent.com/heogun/pico8-os/main/pico8-hashes.txt}
HASH_PUBKEY=${HASH_PUBKEY:-/etc/pico8os/ota-public.pem}
HASH_LISTS=${HASH_LISTS:-/state/pico8-hashes.txt /usr/share/pico8os/pico8-hashes.txt}

# Valid (signed) hash lists, merged, comments stripped.
pico8_hashes() {
	for l in $HASH_LISTS; do
		[ -f "$l" ] && [ -f "$l.sig" ] || continue
		openssl dgst -sha256 -verify "$HASH_PUBKEY" -signature "$l.sig" "$l" >/dev/null 2>&1 || continue
		grep -v -E '^[[:space:]]*(#|$)' "$l"
	done | sort -u
}

# Fetch the newest signed list (needs network); keep it only if it verifies.
update_pico8_hashes() {
	tmp=$(mktemp -d) || return 1
	if wget -q -T 15 -O "$tmp/h.txt" "$PICO8_HASHES_URL" &&
	   wget -q -T 15 -O "$tmp/h.txt.sig" "$PICO8_HASHES_URL.sig" &&
	   openssl dgst -sha256 -verify "$HASH_PUBKEY" -signature "$tmp/h.txt.sig" "$tmp/h.txt" >/dev/null 2>&1; then
		mkdir -p /state
		cp "$tmp/h.txt" /state/pico8-hashes.txt.new && cp "$tmp/h.txt.sig" /state/pico8-hashes.txt.sig &&
			mv /state/pico8-hashes.txt.new /state/pico8-hashes.txt && sync
		rm -rf "$tmp"; return 0
	fi
	rm -rf "$tmp"; return 1
}

# elf_is FILE CLASS MACHINE: ELF header check (class 01=32-bit 02=64-bit,
# machine 28 = ARM, b7 = AArch64; little endian).
elf_is() {
	h=$(od -An -tx1 -N20 "$1" 2>/dev/null | tr -d ' \n')
	[ "${h%"${h#????????}"}" = 7f454c46 ] || return 1                 # \177ELF
	[ "$(printf '%s' "$h" | cut -c9-10)" = "$2" ] || return 1          # class
	[ "$(printf '%s' "$h" | cut -c11-12)" = 01 ] || return 1           # LE
	[ "$(printf '%s' "$h" | cut -c37-38)" = "$3" ]                      # machine
}

# verify_pico8 DIR: prints "<status> <version>", status:
#   ok        every file of this version matches the signed list
#   unknown   sane package, but this version is not on the list (yet)
#   mismatch  a file differs from the list: damaged or modified
#   invalid   not a Raspberry Pi PICO-8 for this CPU
# Returns 0 ok, 1 unknown, 2 mismatch/invalid.
verify_pico8() {
	d=$1 arch=${PICO8_ARCH:-$(uname -m)}
	[ -f "$d/pico8.dat" ] || { echo "invalid -"; return 2; }
	v=$(grep -m1 -o 'PICO-8 v[0-9][0-9.a-z]*' "$d/pico-8_manual.txt" 2>/dev/null); v=${v#PICO-8 v}
	[ -n "$v" ] || v=unknown
	case $arch in
		aarch64|arm64) elf_is "$d/pico8_64" 02 b7 || { echo "invalid $v"; return 2; } ;;
		*) elf_is "$d/pico8_dyn" 01 28 || elf_is "$d/pico8" 01 28 || { echo "invalid $v"; return 2; } ;;
	esac
	list=$(pico8_hashes | awk -v v="$v" '$1 == v')
	if [ -z "$list" ]; then echo "unknown $v"; return 1; fi
	printf '%s\n' "$list" | grep -q ' pico8.dat ' || { echo "unknown $v"; return 1; }
	bad=0
	for f in pico8.dat pico8 pico8_dyn pico8_64 pico8_gpio; do
		[ -f "$d/$f" ] || continue
		want=$(printf '%s\n' "$list" | awk -v f="$f" '$2 == f {print $3}')
		[ -n "$want" ] || { bad=1; break; }               # unexpected file
		[ "$(sha256sum "$d/$f" | cut -d' ' -f1)" = "$want" ] || { bad=1; break; }
	done
	if [ $bad = 1 ]; then echo "mismatch $v"; return 2; fi
	echo "ok $v"; return 0
}
