################################################################################
#
# rk3399-firmware-blobs
#
################################################################################

RK3399_FIRMWARE_BLOBS_VERSION = 9dbf477701ba6b21a83bc46e7c99bcc51bfe49d4
RK3399_FIRMWARE_BLOBS_SITE = $(call github,skiffos,rk3399-firmware-blobs,$(RK3399_FIRMWARE_BLOBS_VERSION))
RK3399_FIRMWARE_BLOBS_LICENSE = BSD-3-Clause
RK3399_FIRMWARE_BLOBS_LICENSE_FILES = LICENSE

RK3399_FIRMWARE_BLOBS_INSTALL_TARGET = NO
RK3399_FIRMWARE_BLOBS_INSTALL_HOST = NO
RK3399_FIRMWARE_BLOBS_INSTALL_IMAGES = YES

define RK3399_FIRMWARE_BLOBS_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/rk3399-firmware-blobs
	cp -dpfr $(@D)/. $(BINARIES_DIR)/rk3399-firmware-blobs/
endef

$(eval $(generic-package))
