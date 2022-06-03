################################################################################
#
# rtk_hciattach
#
################################################################################

RTK_HCIATTACH_VERSION = 20220603
RTK_HCIATTACH_SITE = $(call github,paralin,rtk_hciattach,$(RTK_HCIATTACH_VERSION))

RTK_HCIATTACH_LICENSE = GPL-2.0+
RTK_HCIATTACH_LICENSE_FILES = LICENSE

define RTK_HCIATTACH_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) CC="$(TARGET_CC)" \
		CFLAGS="$(TARGET_CFLAGS)" LDFLAGS="$(TARGET_LDFLAGS)"
endef

define RTK_HCIATTACH_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/rtk_hciattach $(TARGET_DIR)/usr/bin/rtk_hciattach
endef

$(eval $(generic-package))
