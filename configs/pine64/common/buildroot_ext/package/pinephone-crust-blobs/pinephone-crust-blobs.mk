################################################################################
#
# pinephone-crust-blobs
#
################################################################################

PINEPHONE_CRUST_BLOBS_VERSION = crust-20211124
PINEPHONE_CRUST_BLOBS_SITE = $(call github,skiffos,pinephone-crust-blobs,$(PINEPHONE_CRUST_BLOBS_VERSION))
PINEPHONE_CRUST_BLOBS_LICENSE = BSD-3-Clause, GPL-2.0+
PINEPHONE_CRUST_BLOBS_LICENSE_FILES = LICENSE.md

PINEPHONE_CRUST_BLOBS_INSTALL_TARGET = NO
PINEPHONE_CRUST_BLOBS_INSTALL_HOST = NO
PINEPHONE_CRUST_BLOBS_INSTALL_IMAGES = YES

define PINEPHONE_CRUST_BLOBS_INSTALL_IMAGES_CMDS
	cp -dpfr $(@D)/u-boot-sunxi-with-spl.bin $(BINARIES_DIR)
endef

$(eval $(generic-package))
