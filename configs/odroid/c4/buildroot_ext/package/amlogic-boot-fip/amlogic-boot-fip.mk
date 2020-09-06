################################################################################
#
# amlogic-boot-fip
#
################################################################################

AMLOGIC_BOOT_FIP_VERSION = 9f21abeb339b7cdd8c66e3e1c94ee9f133ad762e
AMLOGIC_BOOT_FIP_SITE = $(call github,LibreELEC,amlogic-boot-fip,$(AMLOGIC_BOOT_FIP_VERSION))
AMLOGIC_BOOT_FIP_LICENSE = Proprietary
AMLOGIC_BOOT_FIP_LICENSE_FILES = LICENSE

AMLOGIC_BOOT_FIP_INSTALL_TARGET = NO
AMLOGIC_BOOT_FIP_INSTALL_HOST = NO
AMLOGIC_BOOT_FIP_INSTALL_IMAGES = YES

define AMLOGIC_BOOT_FIP_INSTALL_IMAGES_CMDS
	cp -dpfr $(@D)/odroid-c4/. $(BINARIES_DIR)/amlogic-boot-fip/
endef

$(eval $(generic-package))
