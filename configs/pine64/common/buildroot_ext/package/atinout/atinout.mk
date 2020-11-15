################################################################################
#
# atinout
#
################################################################################

ATINOUT_VERSION = 0.9.1
ATINOUT_SOURCE = atinout-$(ATINOUT_VERSION).tar.gz
ATINOUT_SITE = http://downloads.sourceforge.net/atinout
ATINOUT_LICENSE = GPL-3.0+
ATINOUT_LICENSE_FILES = gplv3.txt

define ATINOUT_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) all \
		CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" \
		LDFLAGS="$(TARGET_LDFLAGS)"
endef

define ATINOUT_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/atinout $(TARGET_DIR)/usr/bin/atinout
	$(INSTALL) -D -m 0644 $(@D)/atinout.1 \
		$(TARGET_DIR)/usr/share/man/man1/atinout.1
endef

$(eval $(generic-package))
