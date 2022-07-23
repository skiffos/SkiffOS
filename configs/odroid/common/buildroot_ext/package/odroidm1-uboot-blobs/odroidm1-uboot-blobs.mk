################################################################################
#
# odroidm1-uboot-blobs
#
################################################################################

ODROIDM1_UBOOT_BLOBS_VERSION = 4711f33b83f8b2671e0196cbad0d0318cad3b454
ODROIDM1_UBOOT_BLOBS_SITE = $(call github,skiffos,odroidm1-uboot-blobs,$(ODROIDM1_UBOOT_BLOBS_VERSION))

ODROIDM1_UBOOT_BLOBS_LICENSE = Various
ODROIDM1_UBOOT_BLOBS_LICENSE_FILES = LICENSE

ODROIDM1_UBOOT_BLOBS_INSTALL_TARGET = NO
ODROIDM1_UBOOT_BLOBS_INSTALL_HOST = NO
ODROIDM1_UBOOT_BLOBS_INSTALL_IMAGES = YES

define ODROIDM1_UBOOT_BLOBS_INSTALL_IMAGES_CMDS
	cp $(@D)/uboot.img $(BINARIES_DIR)/u-boot-odroidm1.img
endef

$(eval $(generic-package))
