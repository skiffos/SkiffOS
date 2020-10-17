################################################################################
#
# ap6256-firmware
#
################################################################################

AP6256_FIRMWARE_VERSION = 7074a2e21dd804e229eab1c031bc00246e9173e0
AP6256_FIRMWARE_SITE = $(call github,paralin,ap6256-firmware,$(AP6256_FIRMWARE_VERSION))

AP6256_FIRMWARE_LICENSE = Proprietary

AP6256_FIRMWARE_FILES += \
	BCM4345C5.hcd \
	brcmfmac43456-sdio.clm_blob \
	fw_bcm43456c5_ag.bin \
	nvram_ap6256.txt

define AP6256_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware/brcm
	$(INSTALL) -D -m 644 $(@D)/BCM4345C5.hcd $(TARGET_DIR)/lib/firmware
	$(INSTALL) -D -m 644 $(@D)/BCM4345C5.hcd $(TARGET_DIR)/lib/firmware/brcm/BCM.hcd
	$(INSTALL) -D -m 644 $(@D)/BCM4345C5.hcd $(TARGET_DIR)/lib/firmware/brcm/
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.txt
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.radxa,rockpi4b.txt
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.radxa,rockpi4c.txt
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.pine64,pinebook-pro.txt
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.pine64,rockpro64-v2.1.txt
	$(INSTALL) -D -m 644 $(@D)/nvram_ap6256.txt $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.rockchip,rk3399-orangepi.txt
	$(INSTALL) -D -m 644 $(@D)/fw_bcm43456c5_ag.bin $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.bin
	$(INSTALL) -D -m 644 $(@D)/brcmfmac43456-sdio.clm_blob $(TARGET_DIR)/lib/firmware/brcm/brcmfmac43456-sdio.clm_blob
endef

$(eval $(generic-package))
