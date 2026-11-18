include $(sort $(wildcard $(BR2_EXTERNAL_PICO8OS_PATH)/package/*/*.mk))

# SDL2 HIDAPI override (see Config.in). This file is included after
# package/*/*.mk, so the later --enable-* wins over sdl2.mk's --disable-*.
# Package prerequisites are expanded when sdl2.mk is evaluated, so adding
# libusb to SDL2_DEPENDENCIES alone would not order the build: add the
# order-only prerequisite on the configure step explicitly as well.
ifeq ($(BR2_PACKAGE_SDL2)$(BR2_PACKAGE_PICO8OS_SDL2_HIDAPI),yy)
SDL2_CONF_OPTS += --enable-hidapi --enable-hidapi-joystick --enable-hidapi-libusb
SDL2_DEPENDENCIES += libusb
$(SDL2_TARGET_CONFIGURE): | libusb
endif
