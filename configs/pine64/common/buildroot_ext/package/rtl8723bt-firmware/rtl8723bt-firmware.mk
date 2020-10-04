################################################################################
#
# rtl8723bt-firmware
#
################################################################################

RTL8723BT_FIRMWARE_VERSION = 8840b1052b4ee426f348cb35e4994c5cafc5fbbd
RTL8723BT_FIRMWARE_SITE = $(call github,paralin,rtl8723bt-firmware,$(RTL8723BT_FIRMWARE_VERSION))

RTL8723BT_FIRMWARE_LICENSE = Proprietary
RTL8723BT_FIRMWARE_ALL_LICENSE_FILES += WHENCE

RTL8723BT_FIRMWARE_FILES += \
	rtl_bt/rtl8723bs_config.bin \
	rtl_bt/rtl8723cs_xx_config.bin \
	rtl_bt/rtl8723cs_xx_fw.bin
RTL8723BT_FIRMWARE_ALL_LICENSE_FILES += LICENCE.rtlwifi_firmware.txt

# Some license files may be listed more than once, so we have to remove
# duplicates
RTL8723BT_FIRMWARE_LICENSE_FILES = $(sort $(RTL8723BT_FIRMWARE_ALL_LICENSE_FILES))

define RTL8723BT_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware
	cd $(@D) && \
		$(TAR) cf install.tar $(sort $(RTL8723BT_FIRMWARE_FILES)) && \
		$(TAR) xf install.tar -C $(TARGET_DIR)/lib/firmware
endef

$(eval $(generic-package))
