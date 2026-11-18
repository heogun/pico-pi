# PICO8-OS shared shell helpers (busybox ash compatible).
# Sourced by pico8-session, pico8-install, init scripts, and the host-side
# post-build script (install_zip only), so keep it POSIX sh.

PICO8_DIR=${PICO8_DIR:-/opt/pico8}
DATA=${DATA:-/data}
STATE_DIR=${STATE_DIR:-/state}

# ---- settings ----
# Settings are split by who may change them:
#   USER_KEYS    PICO8DATA/pico8os.txt: shared with PICO-8 (pico) and the
#                web UI (www); anyone at the console or on a PC may edit them.
#   POLICY_KEYS  $STATE_DIR/policy.txt (root 0600): security policy and the
#                web password. Never read from the shared file after the
#                first boot.
#   WIFI_KEYS    $STATE_DIR/wifi.txt (root 0600): the Wi-Fi network. The
#                Wi-Fi setup page (AP mode) can change these and nothing else.
# Both root-only files are changed only by root (pico8os-agent on behalf of
# the logged-in web UI or the settings cart), on the first boot from
# pico8os.txt, or at any boot from PICOBOOT/pico8os-setup.txt (only a PC or
# root can write the boot partition). See secure_settings_init.
USER_KEYS="CPU_GOVERNOR LANGUAGE OTA_URL EXIT_ACTION PICO8_MODE PICO8_CART PICO8_ARGS VIDEO_DRIVER AUDIO_CARD KEYMAP WATCHDOG HOTKEY BLUETOOTH BT_PAIR_SECONDS"
POLICY_KEYS="DEBUG PICO8_VERIFY WEB_PASSWORD"
WIFI_KEYS="WIFI_SSID WIFI_PSK WIFI_COUNTRY"
CONF_KEYS="$USER_KEYS $POLICY_KEYS $WIFI_KEYS"
USER_CONF="$DATA/pico8os.txt"
POLICY_CONF="$STATE_DIR/policy.txt"
WIFI_CONF="$STATE_DIR/wifi.txt"
PROVISION_NAME=pico8os-setup.txt

say() { printf '%s\n' "$*"; }

# has_word LIST WORD
has_word() { case " $1 " in *" $2 "*) return 0 ;; esac; return 1; }

# conf_file_of KEY -> the file that holds KEY
conf_file_of() {
	if has_word "$USER_KEYS" "$1"; then echo "$USER_CONF"
	elif has_word "$POLICY_KEYS" "$1"; then echo "$POLICY_CONF"
	elif has_word "$WIFI_KEYS" "$1"; then echo "$WIFI_CONF"
	else return 1
	fi
}

# parse_conf FILE KEYS: set the variables KEYS from KEY=VALUE lines of FILE.
# Other keys are ignored and values are never evaluated as shell code.
parse_conf() {
	[ -r "$1" ] || return 0
	while IFS= read -r line || [ -n "$line" ]; do
		line=$(printf '%s' "$line" | tr -d '\r')
		case $line in ''|'#'*) continue ;; *=*) ;; *) continue ;; esac
		key=$(printf '%s' "${line%%=*}" | tr -d ' \t')
		has_word "$2" "$key" || continue
		val=$(printf '%s' "${line#*=}" | sed 's/^[[:space:]]*//')
		case $val in
			\"*) val=${val#\"}; val=${val%%\"*} ;;
			\'*) val=${val#\'}; val=${val%%\'*} ;;
			*) val=${val%%[ 	]#*}; val=$(printf '%s' "$val" | sed 's/[[:space:]]*$//') ;;
		esac
		eval "$key=\$val"
	done < "$1"
}

# Load every setting this user may read (the root-only files are simply
# unreadable for pico and www, which then see the safe defaults).
load_config() {
	EXIT_ACTION=restart PICO8_MODE=splore PICO8_CART='' PICO8_ARGS=''
	VIDEO_DRIVER=kmsdrm AUDIO_CARD=auto KEYMAP=us WATCHDOG=on HOTKEY=on BLUETOOTH=on BT_PAIR_SECONDS=0
	WIFI_SSID='' WIFI_PSK='' WIFI_COUNTRY='' OTA_URL='' WEB_PASSWORD='' LANGUAGE=en
	DEBUG=off CPU_GOVERNOR=performance PICO8_VERIFY=strict
	parse_conf "$USER_CONF" "$USER_KEYS"
	parse_conf "$POLICY_CONF" "$POLICY_KEYS"
	parse_conf "$WIFI_CONF" "$WIFI_KEYS"
	case $DEBUG in on) ;; *) DEBUG=off ;; esac
	case $PICO8_VERIFY in warn) ;; *) PICO8_VERIFY=strict ;; esac
}

# conf_write FILE KEY VALUE: change one KEY=VALUE line of FILE in place,
# keeping comments and order (appends the key if missing, drops duplicates).
# Control characters are removed. Values with spaces, '#' or quotes are
# quoted with whichever quote they do not contain; a value holding both
# kinds cannot be written (returns 2). The line reaches awk through the
# environment, which (unlike awk -v) never interprets backslash escapes.
conf_write() {
	f=$1 key=$2
	val=$(printf '%s' "$3" | tr -d '\000-\037\177')
	case $val in
		*\"*\'*|*\'*\"*) return 2 ;;
		*\"*) line="$key='$val'" ;;
		*[" #'"]*) line="$key=\"$val\"" ;;
		*) line="$key=$val" ;;
	esac
	[ -L "$f" ] && return 1
	tmp=$(mktemp "$f.XXXXXX") || return 1
	{ [ -f "$f" ] && cat "$f"; } | K="$key" L="$line" awk '
		BEGIN { k = ENVIRON["K"]; l = ENVIRON["L"]; done = 0 }
		{ t = $0; sub(/\r$/, "", t); sub(/^[ \t]+/, "", t)
		  if (index(t, k "=") == 1 || match(t, "^" k "[ \t]*=")) {
			if (!done) print l
			done = 1; next
		  }
		  print }
		END { if (!done) print l }' > "$tmp" && mv "$tmp" "$f" || { rm -f "$tmp"; return 1; }
	sync
}

# set_conf KEY VALUE: store one setting in the file it belongs to. The
# root-only files are only writable by root.
set_conf() {
	f=$(conf_file_of "$1") || return 1
	case $f in "$USER_CONF") conf_write "$f" "$1" "$2"; return ;; esac
	[ "$(id -u)" = 0 ] || return 1
	( umask 077; conf_write "$f" "$1" "$2" )
}

state_is_persistent() { awk -v d="$STATE_DIR" '$2 == d && $3 == "ext4" {f = 1} END {exit !f}' /proc/mounts; }

# import_conf SRC KEYS: copy the non-empty KEYS of SRC into the root-only files.
import_conf() {
	[ -r "$1" ] || return 0
	for k in $2; do
		v=$( eval "$k=''"; parse_conf "$1" "$k"; eval "printf '%s' \"\$$k\"" )
		[ -n "$v" ] && set_conf "$k" "$v"
	done
	return 0
}

# strip_conf FILE KEYS: replace KEYS lines of a shared file with a note, so
# no password stays readable there and nobody expects them to work.
strip_conf() {
	[ -f "$1" ] && [ ! -L "$1" ] || return 0
	tmp=$(mktemp "$1.XXXXXX") || return 1
	K="$2" awk '
		BEGIN { n = split(ENVIRON["K"], ks, " "); for (i = 1; i <= n; i++) keys[ks[i]] = 1; c = 0 }
		{ t = $0; sub(/\r$/, "", t); sub(/^[ \t]+/, "", t)
		  if (t !~ /^#/ && index(t, "=") > 0) {
			k = substr(t, 1, index(t, "=") - 1); gsub(/[ \t]/, "", k)
			if (k in keys) { print "# " k ": stored on the console now (web UI, or PICOBOOT/pico8os-setup.txt)"; c++; next }
		  }
		  print }
		END { exit c ? 0 : 1 }' "$1" > "$tmp" && mv "$tmp" "$1" || rm -f "$tmp"
	sync
}

# Early boot, as root, before PICO-8 or the web UI run (S05picodata):
#  - first boot only, on a real state partition: take the policy and Wi-Fi
#    settings the user wrote into pico8os.txt before flashing;
#  - any boot: take them from PICOBOOT/pico8os-setup.txt and delete it;
#  - always: remove them from the shared pico8os.txt.
secure_settings_init() {
	mkdir -p "$STATE_DIR"; chmod 0700 "$STATE_DIR"
	if [ ! -e "$POLICY_CONF" ] && [ ! -e "$WIFI_CONF" ] && state_is_persistent; then
		import_conf "$USER_CONF" "$POLICY_KEYS $WIFI_KEYS"
	fi
	p=$(disk_prefix)1 mnt="$RUN/provision"
	if [ -b "$p" ]; then
		mkdir -p "$mnt" && chmod 700 "$mnt"
		if mount -t vfat -o rw,noatime,nosuid,nodev,noexec "$p" "$mnt" 2>/dev/null; then
			if [ -f "$mnt/$PROVISION_NAME" ]; then
				import_conf "$mnt/$PROVISION_NAME" "$POLICY_KEYS $WIFI_KEYS"
				rm -f "$mnt/$PROVISION_NAME"
				echo "PICO8-OS: settings taken from PICOBOOT/$PROVISION_NAME" > /dev/console
			fi
			umount "$mnt"
		fi
	fi
	( umask 077; for f in "$POLICY_CONF" "$WIFI_CONF"; do [ -f "$f" ] || : > "$f"; chmod 600 "$f"; done )
	strip_conf "$USER_CONF" "$POLICY_KEYS $WIFI_KEYS"
	return 0
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

# ---- PICO-8 package install ----
# Only these regular files are ever taken from a package. The executables
# and pico8.dat are checked against the signed list (verify_pico8); the
# others are never executed. Install metadata (source, verify) lives next
# to the package in <dest>.meta, never inside it.
PICO8_BIN_FILES="pico8.dat pico8 pico8_dyn pico8_64 pico8_gpio"
PICO8_DOC_FILES="pico-8_manual.txt license.txt lexaloffle-pico8.png"
PICO8_MAX_MB=${PICO8_MAX_MB:-96}         # unpacked package, whole zip
PICO8_MAX_FILES=${PICO8_MAX_FILES:-500}

# Private scratch space: a size-limited tmpfs when running as root on the
# console (never the system or data partition), else a plain temp dir
# (tests, PICO8_NO_TMPFS). On the console, no tmpfs means no install: an
# unlimited temp dir could fill the root's RAM disk.
work_open() {
	WORKDIR=$(mktemp -d "${TMPDIR:-/tmp}/pico8os.XXXXXX") || return 1
	chmod 700 "$WORKDIR"
	if [ "$(id -u)" = 0 ] && [ -z "${PICO8_NO_TMPFS:-}" ]; then
		if ! mount -t tmpfs -o "size=$((PICO8_MAX_MB + 8))m,mode=0700,nosuid,nodev,noexec" tmpfs "$WORKDIR" 2>/dev/null; then
			rmdir "$WORKDIR"; WORKDIR=; return 1
		fi
	fi
}
work_close() {
	[ -n "${WORKDIR:-}" ] || return 0
	umount "$WORKDIR" 2>/dev/null
	rm -rf "$WORKDIR"; WORKDIR=
}

# zip_check ZIP: refuse archives that are too big, have too many entries,
# or contain absolute or ".." paths, before anything is unpacked.
zip_check() {
	unzip -l "$1" 2>/dev/null | MAX=$((PICO8_MAX_MB * 1048576)) MAXN=$PICO8_MAX_FILES awk '
		BEGIN { max = ENVIRON["MAX"] + 0; maxn = ENVIRON["MAXN"] + 0 }
		$1 ~ /^[0-9]+$/ && NF >= 4 {
			n++; total += $1
			name = $0; sub(/^ *[0-9]+ +[^ ]+ +[^ ]+ +/, "", name)
			if (name ~ /^\// || name ~ /(^|\/)\.\.(\/|$)/) bad = 1
		}
		END { exit (n == 0 || bad || n > maxn || total > max) }'
}

# install_pico8 SRC DEST: copy PICO-8 from a pico-8_*_raspi.zip or an
# unpacked folder into DEST, atomically, after verify_pico8 checked the very
# files that get installed.
# Returns 0 installed, 1 unusable source, 3 unknown version (strict),
# 4 mismatch / wrong CPU / bad package (always refused).
install_pico8() {
	src=$1 dest=$2 meta="$2.meta"
	sum=$(source_sum "$src")
	if [ -f "$dest/pico8.dat" ] && [ "$(cat "$meta/source" 2>/dev/null)" = "$sum" ]; then
		return 0
	fi
	work_open || { say "ERROR: no temporary space"; return 1; }
	if [ -d "$src" ]; then
		top=$src
		# same limit as for a zip, counted over the files that get copied
		total=0
		for f in $PICO8_BIN_FILES $PICO8_DOC_FILES; do
			[ -f "$top/$f" ] && [ ! -L "$top/$f" ] || continue
			total=$(( total + $(wc -c < "$top/$f") ))
		done
		if [ "$total" -gt $((PICO8_MAX_MB * 1048576)) ]; then
			work_close; say "REFUSED: the PICO-8 files in $(basename "$src") are too large."; return 4
		fi
	else
		if ! zip_check "$src"; then
			work_close; say "REFUSED: $(basename "$src") is not a usable PICO-8 zip (too large or unsafe paths)."; return 4
		fi
		mkdir -p "$WORKDIR/zip"
		set -f
		pats=""; for f in $PICO8_BIN_FILES $PICO8_DOC_FILES; do pats="$pats *$f"; done
		# shellcheck disable=SC2086  # patterns are passed to unzip, not the shell
		unzip -q -o "$src" $pats -d "$WORKDIR/zip" >/dev/null 2>&1; rc=$?
		set +f
		# Info-ZIP: 11 = some patterns matched nothing (e.g. no pico8_64)
		if [ $rc != 0 ] && [ $rc != 11 ]; then
			work_close; say "ERROR: cannot unzip $src"; return 1
		fi
		dats=$(find "$WORKDIR/zip" -name pico8.dat -type f)
		if [ "$(printf '%s\n' "$dats" | grep -c .)" != 1 ]; then
			work_close; say "ERROR: need exactly one pico8.dat in $src (the Raspberry Pi build)"; return 1
		fi
		top=$(dirname "$dats")
	fi
	stage="$WORKDIR/stage"; mkdir -p "$stage"
	for f in $PICO8_BIN_FILES $PICO8_DOC_FILES; do
		[ -e "$top/$f" ] || [ -L "$top/$f" ] || continue
		if [ -L "$top/$f" ] || [ ! -f "$top/$f" ]; then
			work_close; say "REFUSED: $f in $(basename "$src") is not a regular file."; return 4
		fi
		cp "$top/$f" "$stage/$f" || { work_close; say "ERROR: cannot copy $f from $src (too large?)"; return 1; }
	done
	if [ ! -f "$stage/pico8.dat" ]; then
		work_close; say "ERROR: pico8.dat not found in $src (need the Raspberry Pi build)"; return 1
	fi
	# Check the private copy; exactly these bytes get installed.
	result=$(verify_pico8 "$stage"); vrc=$?
	PICO8_VERIFY_RESULT=$result
	if [ $vrc = 2 ] || { [ $vrc = 1 ] && [ "${PICO8_VERIFY:-strict}" != warn ]; }; then
		work_close
		case $result in
			mismatch*) say "REFUSED: PICO-8 $(basename "$src") does not match the known-good hashes (damaged or modified)." ;;
			invalid*) say "REFUSED: $(basename "$src") is not a Raspberry Pi PICO-8 for this console ($(uname -m))." ;;
			*) say "REFUSED: PICO-8 version ${result#* } is not on the verified list yet (PICO8_VERIFY=warn allows it)." ;;
		esac
		[ $vrc = 1 ] && return 3
		return 4
	fi
	tmp="$dest.new"
	rm -rf "$tmp" && mkdir -p "$tmp" && chmod 755 "$tmp"
	if ! cp "$stage"/* "$tmp/"; then
		rm -rf "$tmp"; work_close; say "ERROR: cannot install into $dest"; return 1
	fi
	work_close
	for f in $PICO8_BIN_FILES $PICO8_DOC_FILES; do
		[ -f "$tmp/$f" ] || continue
		case $f in pico8|pico8_dyn|pico8_64|pico8_gpio) chmod 755 "$tmp/$f" ;; *) chmod 644 "$tmp/$f" ;; esac
	done
	rm -rf "$dest.old"
	[ -e "$dest" ] && mv "$dest" "$dest.old"
	mv "$tmp" "$dest"
	rm -rf "$dest.old" "$meta"
	mkdir -p "$meta"
	printf '%s\n' "$sum" > "$meta/source"
	printf '%s\n' "$result" > "$meta/verify"     # "ok 0.2.7" / "unknown 0.2.8"
	sync
}

# Copy a PICO-8 zip from the root of a USB stick (FAT or exFAT, mounted
# read-only without devices, setuid or executables) to /data.
USB_MAX_MB=${USB_MAX_MB:-128}
scan_usb() {
	mnt="$RUN/usb"
	mkdir -p "$mnt" && chmod 700 "$mnt"
	for dev in /dev/sd[a-z][0-9]* /dev/sd[a-z]; do
		[ -b "$dev" ] || continue
		ok=0
		for fs in vfat exfat; do
			mount -t "$fs" -o ro,nosuid,nodev,noexec "$dev" "$mnt" 2>/dev/null && { ok=1; break; }
		done
		[ $ok = 1 ] || continue
		z=$(ls -1 "$mnt"/pico-8*raspi*.zip 2>/dev/null | sort | tail -n 1)
		if [ -n "$z" ] && [ -f "$z" ] && [ ! -L "$z" ]; then
			zb=$(stat -c %s "$z")
			free=$(df -k "$DATA" 2>/dev/null | awk 'NR == 2 {print $4}')
			if [ "$zb" -le $((USB_MAX_MB * 1048576)) ] &&
			   [ $(( ${free:-0} * 1024 - zb )) -ge $((32 * 1048576)) ]; then
				say "Copying $(basename "$z") from $dev ..."
				# to a fresh name first (O_EXCL), then renamed into place
				t=$(mktemp "$DATA/.usb.XXXXXX") &&
				if cp "$z" "$t" && mv "$t" "$DATA/$(basename "$z")"; then sync
				else rm -f "$t"; fi
				umount "$mnt"
				return 0
			fi
			say "$(basename "$z") is too large or PICO8DATA is full."
		fi
		umount "$mnt"
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

# JSON string escaping for the web API.
json_str() {
	printf '"%s"' "$(printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' -e 's/\t/\\t/g' | tr -d '\r' | awk 'NR>1{printf "\\n"} {printf "%s", $0}')"
}

current_ip() {
	ip -4 -o addr show scope global 2>/dev/null | awk '{sub(/\/.*/, "", $4); print $4; exit}'
}

# secret_file FILE LEN: a random password kept in a root-only state file.
secret_file() {
	if [ ! -s "$1" ]; then
		( umask 077; tr -dc 'a-km-z2-9' < /dev/urandom 2>/dev/null | head -c "$2" > "$1.tmp" && mv "$1.tmp" "$1" )
		sync
	fi
	chmod 600 "$1" 2>/dev/null
	cat "$1"
}

# Web UI password: WEB_PASSWORD (root-only policy file), else one generated
# on first boot and kept on the state partition.
web_password() {
	if [ -n "$WEB_PASSWORD" ]; then echo "$WEB_PASSWORD"; return; fi
	secret_file "$STATE_DIR/web-password" 8
}

# WPA2 password of the Wi-Fi setup access point (shown in the settings cart
# and wifi-setup.txt).
ap_password() { secret_file "$STATE_DIR/ap-password" 10; }

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
# Requests: $PRIV_DIR (root:www 0730): www can drop requests but cannot list
# or read other requests. Answers: $PRIV_ANS (root:www 0750): only root
# creates files there, www reads its answer by the unique request name; the
# agent deletes old answers. Arguments are one per line, so they must not
# contain line breaks (control characters are removed).
PRIV_DIR="$RUN/priv"
PRIV_ANS="$RUN/priv-ans"
priv() {
	id="$$.$(date +%s).$(od -An -N8 -tx1 /dev/urandom | tr -d ' \n')"
	for a in "$@"; do printf '%s' "$a" | tr -d '\000-\037\177'; echo; done > "$PRIV_DIR/$id.tmp" || return 125
	mv "$PRIV_DIR/$id.tmp" "$PRIV_DIR/$id.req" || return 125
	i=0 max=$(( ${PRIV_TIMEOUT:-30} * 5 ))
	while [ ! -f "$PRIV_ANS/$id.done" ]; do
		i=$((i + 1)); [ $i -gt $max ] && return 124
		sleep 0.2
	done
	cat "$PRIV_ANS/$id.out" 2>/dev/null
	rc=$(cat "$PRIV_ANS/$id.done")
	return "${rc:-1}"
}

# ---- PICO-8 package verification ----
# Lexaloffle publishes no checksums, so PICO8-OS keeps its own list of
# known-good builds: pico8-hashes.txt ("<version> <file> <sha256>"), signed
# with the OTA key. A copy ships in the image; a newer one is fetched from
# PICO8_HASHES_URL and used only if its signature verifies.
PICO8_HASHES_URL=${PICO8_HASHES_URL:-https://raw.githubusercontent.com/heogun/pico8-os/main/pico8-hashes.txt}
HASH_PUBKEY=${HASH_PUBKEY:-/etc/pico8os/ota-public.pem}
HASH_LISTS=${HASH_LISTS:-$STATE_DIR/pico8-hashes.txt /usr/share/pico8os/pico8-hashes.txt}

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
	if wget -q -T 15 -O - "$PICO8_HASHES_URL" | head -c 65536 > "$tmp/h.txt" &&
	   wget -q -T 15 -O - "$PICO8_HASHES_URL.sig" | head -c 1024 > "$tmp/h.txt.sig" &&
	   openssl dgst -sha256 -verify "$HASH_PUBKEY" -signature "$tmp/h.txt.sig" "$tmp/h.txt" >/dev/null 2>&1; then
		mkdir -p "$STATE_DIR"
		cp "$tmp/h.txt" "$STATE_DIR/pico8-hashes.txt.new" && cp "$tmp/h.txt.sig" "$STATE_DIR/pico8-hashes.txt.sig" &&
			mv "$STATE_DIR/pico8-hashes.txt.new" "$STATE_DIR/pico8-hashes.txt" && sync
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
	for f in $PICO8_BIN_FILES; do
		[ -f "$d/$f" ] || continue
		want=$(printf '%s\n' "$list" | awk -v f="$f" '$2 == f {print $3}')
		[ -n "$want" ] || { bad=1; break; }               # unexpected file
		[ "$(sha256sum "$d/$f" | cut -d' ' -f1)" = "$want" ] || { bad=1; break; }
	done
	if [ $bad = 1 ]; then echo "mismatch $v"; return 2; fi
	echo "ok $v"; return 0
}
