################################################################################
#
# sdl-gamecontrollerdb
#
################################################################################

# 2026-11-17
SDL_GAMECONTROLLERDB_VERSION = 4e87e3c6c2574f49e1cdf8526b6f829b61e5ccb3
SDL_GAMECONTROLLERDB_SITE = $(call github,mdqinc,SDL_GameControllerDB,$(SDL_GAMECONTROLLERDB_VERSION))
SDL_GAMECONTROLLERDB_LICENSE = Zlib
SDL_GAMECONTROLLERDB_LICENSE_FILES = LICENSE

# Only the Linux mappings are useful on the target.
define SDL_GAMECONTROLLERDB_INSTALL_TARGET_CMDS
	$(INSTALL) -d $(TARGET_DIR)/usr/share/sdl
	grep -E '^#|platform:Linux' $(@D)/gamecontrollerdb.txt \
		> $(TARGET_DIR)/usr/share/sdl/gamecontrollerdb.txt
endef

$(eval $(generic-package))
