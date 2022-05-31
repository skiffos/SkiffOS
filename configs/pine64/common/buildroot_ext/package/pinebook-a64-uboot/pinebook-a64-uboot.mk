################################################################################
#
# pinebook-a64-uboot
#
################################################################################

PINEBOOK_A64_UBOOT_VERSION = 20200214
PINEBOOK_A64_UBOOT_SITE = https://dl.slarm64.org/slackware/images/pinebook
PINEBOOK_A64_UBOOT_SOURCE = boot-$(PINEBOOK_A64_UBOOT_VERSION).tar.xz
PINEBOOK_A64_UBOOT_LICENSE = GPL-2.0+

PINEBOOK_A64_UBOOT_INSTALL_TARGET = NO
PINEBOOK_A64_UBOOT_INSTALL_HOST = NO
PINEBOOK_A64_UBOOT_INSTALL_IMAGES = YES

define PINEBOOK_A64_UBOOT_INSTALL_IMAGES_CMDS
	OUT="$(BINARIES_DIR)/pinebook-a64-uboot"; \
		mkdir -p $$OUT; \
		cp -dpfr $(@D)/. $${OUT}
endef

$(eval $(generic-package))
