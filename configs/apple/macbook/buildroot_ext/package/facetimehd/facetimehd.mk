################################################################################
#
# facetimehd
#
################################################################################

FACETIMEHD_VERSION = 8431504df5a1d058fc5888f6bb695de859dbf22f
FACETIMEHD_SITE = $(call github,patjak,facetimehd,$(FACETIMEHD_VERSION))
FACETIMEHD_LICENSE = GPL-2.0
FACETIMEHD_LICENSE_FILES = LICENSE

FACETIMEHD_MODULE_MAKE_OPTS = \
	KVERSION=$(LINUX_VERSION_PROBED) \
	KDIR=$(LINUX_DIR) \
	USER_EXTRA_CFLAGS="-DCONFIG_$(call qstrip,$(BR2_ENDIAN))_ENDIAN"

define FACETIMEHD_LINUX_CONFIG_FIXUPS
	$(call KCONFIG_SET_OPT,CONFIG_USB_G_WEBCAM,m)
	$(call KCONFIG_SET_OPT,CONFIG_VIDEOBUF2_DMA_SG,m)
endef

$(eval $(kernel-module))
$(eval $(generic-package))
