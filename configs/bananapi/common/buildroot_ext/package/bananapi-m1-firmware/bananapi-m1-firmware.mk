################################################################################
#
# bananapi-m1-firmware
#
################################################################################

BANANAPI_M1_FIRMWARE_VERSION = 268a1c4c4e41d458311a5e1fe383c96d5aaad2ab
BANANAPI_M1_FIRMWARE_SITE = $(call github,paralin,BPI-Mainline-bsp,$(BANANAPI_M1_FIRMWARE_VERSION))

define BANANAPI_M1_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware/brcm
	$(INSTALL) -D $(@D)/package/bcm_firmware/brcm/* $(TARGET_DIR)/lib/firmware/brcm
endef

$(eval $(generic-package))
