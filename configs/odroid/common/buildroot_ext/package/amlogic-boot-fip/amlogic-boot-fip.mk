################################################################################
#
# amlogic-boot-fip
#
################################################################################

AMLOGIC_BOOT_FIP_VERSION = 1895ed80729ff73cfe2ff65e3595574ae5234644
AMLOGIC_BOOT_FIP_SITE = $(call github,LibreELEC,amlogic-boot-fip,$(AMLOGIC_BOOT_FIP_VERSION))
AMLOGIC_BOOT_FIP_LICENSE = Proprietary
AMLOGIC_BOOT_FIP_LICENSE_FILES = LICENSE

AMLOGIC_BOOT_FIP_INSTALL_TARGET = NO
AMLOGIC_BOOT_FIP_INSTALL_HOST = NO
AMLOGIC_BOOT_FIP_INSTALL_IMAGES = YES

define AMLOGIC_BOOT_FIP_INSTALL_IMAGES_CMDS
	cp -dpfr $(@D)/$(BR2_PACKAGE_AMLOGIC_BOOT_FIP_BOARD)/. \
		$(BINARIES_DIR)/amlogic-boot-fip/
endef

$(eval $(generic-package))
