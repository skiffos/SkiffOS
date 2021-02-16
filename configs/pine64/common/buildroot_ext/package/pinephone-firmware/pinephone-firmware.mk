################################################################################
#
# pinephone-firmware
#
################################################################################

PINEPHONE_FIRMWARE_VERSION = 4ec2645b007ba4c3f2962e38b50c06f274abbf7c
PINEPHONE_FIRMWARE_SITE = $(call github,paralin,megous-linux-firmware,$(PINEPHONE_FIRMWARE_VERSION))

PINEPHONE_FIRMWARE_DEPENDENCIES = linux-firmware
PINEPHONE_FIRMWARE_LICENSE = Proprietary

PINEPHONE_FIRMWARE_FILES += \
	anx7688-fw.bin \
	brcm/BCM20702A1.hcd \
	brcm/BCM4345C5.hcd \
	brcm/brcmfmac43362-sdio.bin \
	brcm/brcmfmac43362-sdio.txt \
	hm5065-af.bin \
	hm5065-init.bin \
	ov5640_af.bin \
	rtl_bt/rtl8723bs_config-pine64.bin \
	rtl_bt/rtl8723cs_xx_config-pinephone.bin \
	rtl_bt/rtl8723cs_xx_fw.bin \
	rtlwifi/rtl8188eufw.bin

define PINEPHONE_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware
	cd $(@D) && \
		$(TAR) cf install.tar $(sort $(PINEPHONE_FIRMWARE_FILES)) && \
		$(TAR) xf install.tar -C $(TARGET_DIR)/lib/firmware
endef

$(eval $(generic-package))
