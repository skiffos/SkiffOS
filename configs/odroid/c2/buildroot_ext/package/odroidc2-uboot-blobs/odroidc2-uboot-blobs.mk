################################################################################
#
# odroidc2-uboot-blobs
#
################################################################################

ODROIDC2_UBOOT_BLOBS_VERSION = 47c5aac4bcac6f067cebe76e41fb9924d45b429c
ODROIDC2_UBOOT_BLOBS_SITE = $(call github,armbian,odroidc2-blobs,$(ODROIDC2_UBOOT_BLOBS_VERSION))
ODROIDC2_UBOOT_BLOBS_LICENSE = Proprietary

ODROIDC2_UBOOT_BLOBS_INSTALL_TARGET = NO
ODROIDC2_UBOOT_BLOBS_INSTALL_HOST = NO
ODROIDC2_UBOOT_BLOBS_INSTALL_IMAGES = YES

define ODROIDC2_UBOOT_BLOBS_INSTALL_IMAGES_CMDS
	cp -dpfr $(@D)/. $(BINARIES_DIR)/odroidc2-uboot-blobs/
endef

$(eval $(generic-package))
