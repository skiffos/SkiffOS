################################################################################
#
# odroidxu-uboot-blobs
#
################################################################################

# odroidxu4-v2017.05
ODROIDXU_UBOOT_BLOBS_VERSION = 42ac93dcfbbb8a08c2bdc02e19f96eb35a81891a
ODROIDXU_UBOOT_BLOBS_SITE = $(call github,hardkernel,u-boot,$(ODROIDXU_UBOOT_BLOBS_VERSION))

ODROIDXU_UBOOT_BLOBS_LICENSE = GPL-2.0+
HARDKERNEL_BOOT_LICENSE_FILES = Licenses/gpl-2.0.txt

ODROIDXU_UBOOT_BLOBS_INSTALL_TARGET = NO
ODROIDXU_UBOOT_BLOBS_INSTALL_HOST = NO
ODROIDXU_UBOOT_BLOBS_INSTALL_IMAGES = YES

define ODROIDXU_UBOOT_BLOBS_INSTALL_IMAGES_CMDS
	cp $(@D)/sd_fuse/bl1.bin.hardkernel \
		$(@D)/sd_fuse/bl2.bin.hardkernel.720k_uboot \
		$(@D)/sd_fuse/tzsw.bin.hardkernel \
		$(BINARIES_DIR)/
endef

$(eval $(generic-package))
