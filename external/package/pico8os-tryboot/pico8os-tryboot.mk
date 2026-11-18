################################################################################
#
# pico8os-tryboot
#
################################################################################

PICO8OS_TRYBOOT_VERSION = 1.0
PICO8OS_TRYBOOT_SITE = $(BR2_EXTERNAL_PICO8OS_PATH)/package/pico8os-tryboot/src
PICO8OS_TRYBOOT_SITE_METHOD = local
PICO8OS_TRYBOOT_LICENSE = MIT

define PICO8OS_TRYBOOT_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) -std=c99 -Wall \
		-o $(@D)/pico8os-tryboot $(@D)/pico8os-tryboot.c
endef

define PICO8OS_TRYBOOT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0700 $(@D)/pico8os-tryboot $(TARGET_DIR)/usr/sbin/pico8os-tryboot
endef

$(eval $(generic-package))
