################################################################################
#
# screen-fetch
#
################################################################################

SCREEN_FETCH_VERSION = v3.9.1
SCREEN_FETCH_SITE = $(call github,KittyKatt,screenFetch,$(SCREEN_FETCH_VERSION))
SCREEN_FETCH_LICENSE = GPL-3.0+
SCREEN_FETCH_LICENSE_FILES = COPYING

define SCREEN_FETCH_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/screenfetch-dev \
		$(TARGET_DIR)/usr/bin/screenfetch
endef

$(eval $(generic-package))

