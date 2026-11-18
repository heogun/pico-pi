# PICO8-OS build entry point (Linux host, or inside the Docker builder).
#   make rpi4          build dist/pico8os-rpi4.img
#   make qemu          build the QEMU test image
#   make docker-rpi4   same, inside Docker (macOS / any host)

BR_VERSION ?= 2026.02.3
# sha256 of buildroot-$(BR_VERSION).tar.xz, from the release's signed
# .tar.xz.sign (update both together).
BR_SHA256  ?= 5a59e7501b0b4ec52c41f4bfa79412320e0b37eae5f719605a258e8d0c6fc7fb
BR_DIR     ?= $(CURDIR)/buildroot
OUT_ROOT   ?= $(CURDIR)/output
DIST_DIR   ?= $(CURDIR)/dist
EXT        := $(CURDIR)/external
# Extra Kconfig fragment appended to every board (CI uses it for ccache).
EXTRA_CONFIG ?=
# Packages built in parallel (needs BR2_PER_PACKAGE_DIRECTORIES, which
# common.config enables). Each package also uses all cores internally.
BR_JOBS ?= $(shell nproc 2>/dev/null || sysctl -n hw.ncpu 2>/dev/null || echo 2)
KEYS       := $(CURDIR)/keys

# Image/OTA version: sortable as text (newer = greater).
PICO8OS_VERSION ?= $(shell date -u +%Y.%m.%d-%H%M)
export PICO8OS_VERSION

BOARDS := rpi0 rpi2 rpi3 rpi4 rpi5 qemu

# Upstream Buildroot defconfig each board starts from (qemu: none).
base_rpi0 := raspberrypi0w_defconfig
base_rpi2 := raspberrypi2_defconfig
base_rpi3 := raspberrypi3_defconfig
base_rpi4 := raspberrypi4_defconfig
base_rpi5 := raspberrypi5_defconfig
base_qemu :=

frags_rpi0 := common rpi-common rpi0
frags_rpi2 := common rpi-common rpi2
frags_rpi3 := common rpi-common rpi3
frags_rpi4 := common rpi-common rpi4
frags_rpi5 := common rpi-common rpi5
frags_qemu := common qemu

.PHONY: help all buildroot keys i18n webfonts $(BOARDS) $(addprefix menuconfig-,$(BOARDS)) \
	$(addprefix docker-,$(BOARDS)) qemu-run clean

help:
	@echo "Targets: $(BOARDS) all docker-<board> menuconfig-<board> keys i18n webfonts qemu-run clean"
	@echo "  rpi0 = Pi 1 / Zero / Zero W     rpi2 = Pi 2"
	@echo "  rpi3 = Pi 3 / Zero 2 W          rpi4 = Pi 4 / 400"
	@echo "  rpi5 = Pi 5 / 500 (64-bit)      qemu = QEMU virt test image"

all: $(BOARDS)

buildroot: $(BR_DIR)/Makefile

# OTA signing key (ECDSA P-256). The private key never leaves the build host;
# images only carry ota-public.pem. Keep keys/ safe: whoever has the private
# key can push updates to your consoles. Lose it and you can only update by
# re-flashing the SD card.
# Builds need only keys/ota-public.pem (kept in git). Bundles are signed
# when keys/ota-private.pem exists, else left for scripts/sign-update.sh
# (CI signs in a separate job that never runs the build).
#   make keys   create the private key if missing and (re)write the public one
keys: $(KEYS)/ota-private.pem
	openssl ec -in $< -pubout -out $(KEYS)/ota-public.pem

$(KEYS)/ota-private.pem:
	mkdir -p $(KEYS)
	umask 077 && openssl ecparam -name prime256v1 -genkey -noout -out $@
	chmod 600 $@

$(KEYS)/ota-public.pem:
	@echo "missing $@: run 'make keys' (new key) or restore it from git" >&2; exit 1

# Settings-cart languages: regenerate lang_*.p8 after editing
# tools/i18n/cart-strings.json (the generated carts are kept in git, so normal
# builds do not need the font). Font: Fusion Pixel Font 8px, SIL OFL 1.1.
FONT_VER    := 2026.11.10
FONT_ZIP    := fusion-pixel-font-8px-monospaced-bdf-v$(FONT_VER).zip
FONT_SHA256 := f4eb1511153c43019883bd4402457e52ba8ef2062a1445ad9d7cf8ab0e6c5dd3
FONT_CACHE  := $(CURDIR)/.cache/fusion-pixel-$(FONT_VER)
CART_DIR    := $(EXT)/rootfs-overlay/usr/share/pico8os/cart

$(FONT_CACHE)/OFL.txt:
	mkdir -p $(FONT_CACHE)
	curl -fL -o $(FONT_CACHE)/$(FONT_ZIP) \
		https://github.com/TakWolf/fusion-pixel-font/releases/download/$(FONT_VER)/$(FONT_ZIP)
	echo "$(FONT_SHA256)  $(FONT_CACHE)/$(FONT_ZIP)" | shasum -a 256 -c -
	cd $(FONT_CACHE) && unzip -q -o $(FONT_ZIP)

i18n: $(FONT_CACHE)/OFL.txt
	python3 -I tools/gen-cart-lang.py $(FONT_CACHE) tools/i18n/cart-strings.json $(CART_DIR)

# Web UI fonts: Noto Sans (+KR/SC/JP), SIL OFL 1.1, subset to what the pages
# use (tools/gen-webfonts.py). Rerun after changing www/i18n.js or *.html.
NOTO_COMMIT := 7af0d90b4d532ffa4b041937b560c6df4e7b1e95
NOTO_CACHE  := $(CURDIR)/.cache/noto-$(NOTO_COMMIT)
NOTO_BASE   := https://raw.githubusercontent.com/google/fonts/$(NOTO_COMMIT)/ofl
WWW_DIR     := $(EXT)/rootfs-overlay/usr/share/pico8os/www
VENV        := $(CURDIR)/.cache/venv

$(NOTO_CACHE)/OFL.txt:
	mkdir -p $(NOTO_CACHE)
	curl -fL -o $(NOTO_CACHE)/NotoSans.ttf   "$(NOTO_BASE)/notosans/NotoSans%5Bwdth,wght%5D.ttf"
	curl -fL -o $(NOTO_CACHE)/NotoSansKR.ttf "$(NOTO_BASE)/notosanskr/NotoSansKR%5Bwght%5D.ttf"
	curl -fL -o $(NOTO_CACHE)/NotoSansSC.ttf "$(NOTO_BASE)/notosanssc/NotoSansSC%5Bwght%5D.ttf"
	curl -fL -o $(NOTO_CACHE)/NotoSansJP.ttf "$(NOTO_BASE)/notosansjp/NotoSansJP%5Bwght%5D.ttf"
	curl -fL -o $(NOTO_CACHE)/OFL.txt.tmp    "$(NOTO_BASE)/notosans/OFL.txt"
	cd $(NOTO_CACHE) && printf '%s\n' \
		"bfb7bb691513f12e734dc346c03a03f784912432d7e3fa8e56efcf906fe86b3d  NotoSans.ttf" \
		"194018e6b2b293a7964f037b25c0249ce1418bc9ab3c971060a03aa57861e252  NotoSansKR.ttf" \
		"a3041811a78c361b1de50f953c805e0244951c21c5bd412f7232ef0d899af0da  NotoSansSC.ttf" \
		"c2f3b4d463500a2ddcd3849cded1fceeb9fd6d1c32e6cbecd568453ba50fc68f  NotoSansJP.ttf" \
		"cee9892f9f0cc8fe882c9e9537ee6a89621d86ee7ceaf70b02e2b2b1c25c061a  OFL.txt.tmp" \
		| shasum -a 256 -c -
	mv $(NOTO_CACHE)/OFL.txt.tmp $(NOTO_CACHE)/OFL.txt

$(VENV)/bin/python:
	python3 -m venv $(VENV)
	$(VENV)/bin/pip install -q fonttools==4.55.3 brotli==1.1.0

webfonts: $(NOTO_CACHE)/OFL.txt $(VENV)/bin/python
	$(VENV)/bin/python -I tools/gen-webfonts.py $(NOTO_CACHE) $(WWW_DIR)

# Download, check against the pinned hash, then unpack (never unpack first).
$(BR_DIR)/Makefile:
	mkdir -p $(BR_DIR) $(CURDIR)/.cache
	curl -fL -o $(CURDIR)/.cache/buildroot-$(BR_VERSION).tar.xz.part \
		https://buildroot.org/downloads/buildroot-$(BR_VERSION).tar.xz
	echo "$(BR_SHA256)  $(CURDIR)/.cache/buildroot-$(BR_VERSION).tar.xz.part" | shasum -a 256 -c - \
		|| { rm -f $(CURDIR)/.cache/buildroot-$(BR_VERSION).tar.xz.part; exit 1; }
	tar -xJf $(CURDIR)/.cache/buildroot-$(BR_VERSION).tar.xz.part -C $(BR_DIR) --strip-components=1
	rm -f $(CURDIR)/.cache/buildroot-$(BR_VERSION).tar.xz.part

# $(1) = board
define BOARD_RULES
$(OUT_ROOT)/$(1)/.config: $(BR_DIR)/Makefile $(addprefix $(EXT)/fragments/,$(addsuffix .config,$(frags_$(1)))) $(EXTRA_CONFIG)
	mkdir -p $(OUT_ROOT)/$(1)
	cat $(if $(base_$(1)),$(BR_DIR)/configs/$(base_$(1))) \
		$(addprefix $(EXT)/fragments/,$(addsuffix .config,$(frags_$(1)))) $(EXTRA_CONFIG) \
		> $(OUT_ROOT)/$(1)/pico8os_defconfig
	$(MAKE) -C $(BR_DIR) O=$(OUT_ROOT)/$(1) BR2_EXTERNAL=$(EXT) \
		BR2_DEFCONFIG=$(OUT_ROOT)/$(1)/pico8os_defconfig defconfig

$(1): $(OUT_ROOT)/$(1)/.config $(KEYS)/ota-public.pem
	$(MAKE) -C $(BR_DIR) O=$(OUT_ROOT)/$(1) -j$(BR_JOBS)
	mkdir -p $(DIST_DIR)
	cp $(OUT_ROOT)/$(1)/images/sdcard.img $(DIST_DIR)/pico8os-$(1).img
	cp $(OUT_ROOT)/$(1)/images/*.pico8os-update $(DIST_DIR)/
	@echo ">>> $(DIST_DIR)/pico8os-$(1).img + OTA bundle in $(DIST_DIR)"

menuconfig-$(1): $(OUT_ROOT)/$(1)/.config
	$(MAKE) -C $(BR_DIR) O=$(OUT_ROOT)/$(1) menuconfig

docker-$(1):
	./scripts/docker-build.sh $(1)
endef

$(foreach b,$(BOARDS),$(eval $(call BOARD_RULES,$(b))))

qemu-run:
	./scripts/run-qemu.sh

clean:
	rm -rf $(OUT_ROOT) $(DIST_DIR)
