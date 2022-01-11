################################################################################
#
# facetimehd-firmware
#
################################################################################

FACETIMEHD_FIRMWARE_VERSION = 36461999cc285271986d1fb034b90d5fa6f82238
FACETIMEHD_FIRMWARE_SITE = $(call github,patjak,facetimehd-firmware,$(FACETIMEHD_FIRMWARE_VERSION))

FACETIMEHD_FIRMWARE_LICENSE = Proprietary, GPL-2.0

define FACETIMEHD_FIRMWARE_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) all
endef

define FACETIMEHD_FIRMWARE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware/facetimehd
	$(INSTALL) -m 0644 $(@D)/firmware.bin \
		$(TARGET_DIR)/lib/firmware/facetimehd/firmware.bin
endef

$(eval $(generic-package))
