#!/bin/sh
# Sign a PICO8-OS update bundle: adds manifest.sig (ECDSA P-256 / SHA-256
# over the manifest) to the bundle tar. Runs apart from the build, so the
# private key never sits in a workspace that builds third-party code (CI:
# the "sign" job in .github/workflows/build.yml).
#   scripts/sign-update.sh BUNDLE.pico8os-update [KEY]   (default keys/ota-private.pem)
set -eu
bundle=${1:?bundle}
key=${2:-$(dirname "$0")/../keys/ota-private.pem}
[ -f "$key" ] || { echo "missing $key" >&2; exit 1; }
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
tar -xOf "$bundle" manifest > "$tmp/manifest"
grep -q '^rootfs_raw_sha256=[0-9a-f]\{64\}$' "$tmp/manifest" || { echo "$bundle: manifest without rootfs_raw_sha256" >&2; exit 1; }
if tar -tf "$bundle" | grep -qx manifest.sig; then
	echo "$bundle: already signed" >&2; exit 1
fi
openssl dgst -sha256 -sign "$key" -out "$tmp/manifest.sig" "$tmp/manifest"
# the public half must verify it (catches a wrong key)
openssl ec -in "$key" -pubout -out "$tmp/pub.pem" 2>/dev/null
openssl dgst -sha256 -verify "$tmp/pub.pem" -signature "$tmp/manifest.sig" "$tmp/manifest" >/dev/null
tar -C "$tmp" --owner=0 --group=0 --numeric-owner -rf "$bundle" manifest.sig
echo "signed $bundle"
