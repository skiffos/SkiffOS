################################################################################
#
# rkbin-firmware
#
################################################################################

RKBIN_FIRMWARE_VERSION = c393698bcae6d145a7858d93559715cf5c48443f
RKBIN_FIRMWARE_SITE = $(call github,skiffos,rkbin,$(RKBIN_FIRMWARE_VERSION))
RKBIN_FIRMWARE_LICENSE = Rockchip
RKBIN_FIRMWARE_LICENSE_FILES = LICENSE.TXT

RKBIN_FIRMWARE_INSTALL_TARGET = NO
RKBIN_FIRMWARE_INSTALL_HOST = NO
RKBIN_FIRMWARE_INSTALL_IMAGES = YES

RKBIN_FIRMWARE_TARGET = $(call qstrip,$(BR2_PACKAGE_RKBIN_FIRMWARE_TARGET))
define RKBIN_FIRMWARE_INSTALL_IMAGES_CMDS
	cp -dpfr $(@D)/$(RKBIN_FIRMWARE_TARGET)/. \
		$(BINARIES_DIR)/rkbin-firmware/
endef

$(eval $(generic-package))
