################################################################################
#
# pico8-hotkey
#
################################################################################

PICO8_HOTKEY_VERSION = 1.0
PICO8_HOTKEY_SITE = $(BR2_EXTERNAL_PICOPI_PATH)/package/pico8-hotkey/src
PICO8_HOTKEY_SITE_METHOD = local
PICO8_HOTKEY_LICENSE = MIT

define PICO8_HOTKEY_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -std=c99 -Wall \
		-o $(@D)/pico8-hotkey $(@D)/pico8-hotkey.c
endef

define PICO8_HOTKEY_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/pico8-hotkey $(TARGET_DIR)/usr/bin/pico8-hotkey
endef

$(eval $(generic-package))
