################################################################################
#
# odroidn2-uboot-blobs
#
################################################################################

# WORKAROUND for 2022.07 not booting on the EMMC:
# https://github.com/skiffos/SkiffOS/issues/221

ODROIDN2_UBOOT_BLOBS_VERSION = 2015.01-10
ODROIDN2_UBOOT_BLOBS_SITE = http://mirror.archlinuxarm.org/aarch64/alarm
ODROIDN2_UBOOT_BLOBS_SOURCE = uboot-odroid-n2-$(ODROIDN2_UBOOT_BLOBS_VERSION)-aarch64.pkg.tar.xz

ODROIDN2_UBOOT_BLOBS_LICENSE = GPL-2.0

ODROIDN2_UBOOT_BLOBS_INSTALL_TARGET = NO
ODROIDN2_UBOOT_BLOBS_INSTALL_HOST = NO
ODROIDN2_UBOOT_BLOBS_INSTALL_IMAGES = YES

define ODROIDN2_UBOOT_BLOBS_INSTALL_IMAGES_CMDS
	cp $(@D)/u-boot.bin $(BINARIES_DIR)/u-boot-signed.bin.sd.bin
endef

$(eval $(generic-package))
