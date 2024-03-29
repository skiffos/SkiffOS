################################################################################
#
# rk3399-firmware-blobs
#
################################################################################

RK3399_FIRMWARE_BLOBS_VERSION = be238631aad6031c8d2a79ca3776dd9074d8c61e
RK3399_FIRMWARE_BLOBS_SITE = $(call github,skiffos,rk3399-firmware-blobs,$(RK3399_FIRMWARE_BLOBS_VERSION))
RK3399_FIRMWARE_BLOBS_LICENSE = BSD-3-Clause
RK3399_FIRMWARE_BLOBS_LICENSE_FILES = LICENSE

RK3399_FIRMWARE_BLOBS_INSTALL_TARGET = NO
RK3399_FIRMWARE_BLOBS_INSTALL_HOST = NO
RK3399_FIRMWARE_BLOBS_INSTALL_IMAGES = YES

RK3399_FIRMWARE_BLOBS_VARIANT = $(BR2_PACKAGE_RK3399_FIRMWARE_BLOBS_VARIANT)

define RK3399_FIRMWARE_BLOBS_INSTALL_IMAGES_CMDS
	OUT="$(BINARIES_DIR)/rk3399-firmware-blobs"; \
		mkdir -p $$OUT; \
		cp $(@D)/bl31.elf $${OUT}; \
		cp -dpfr $(@D)/$(RK3399_FIRMWARE_BLOBS_VARIANT)/. $${OUT}
endef

$(eval $(generic-package))
