################################################################################
#
# linux-firmware-neptune
#
################################################################################

# https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-main
# linux-firmware-neptune-20230217-1.src.tar.gz
# jupiter-20230217-rtw-debug
LINUX_FIRMWARE_NEPTUNE_VERSION = 20230217
LINUX_FIRMWARE_NEPTUNE_SITE = $(call github,skiffos,linux-firmware-neptune,jupiter-$(LINUX_FIRMWARE_NEPTUNE_VERSION)-rtw-debug)

LINUX_FIRMWARE_NEPTUNE_DEPENDENCIES = linux-firmware

LINUX_FIRMWARE_NEPTUNE_LICENSE = Proprietary
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += WHENCE

LINUX_FIRMWARE_NEPTUNE_DIRS += \
	3com \
	amd \
	amd-ucode \
	ath10k \
	ath11k \
	bnx2* \
	brcm \
	carl9170* \
	cs35l41-dsp1-* \
	qed \
	silabs
LINUX_FIRMWARE_NEPTUNE_FILES += \
	TDA7706* \
	atmel/wilc1000* \
	atmsar11.fw \
	cbfw* \
	tr_smctr*

LINUX_FIRMWARE_NEPTUNE_DIRS += amdgpu
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += LICENSE.amdgpu

LINUX_FIRMWARE_NEPTUNE_FILES += intel/ibt-* intel/ice* intelliport2*
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += LICENCE.ibt_firmware

LINUX_FIRMWARE_NEPTUNE_FILES += cxgb*
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += LICENCE.chelsio_firmware

LINUX_FIRMWARE_NEPTUNE_FILES += iwlwifi-*
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += LICENCE.iwlwifi_firmware

LINUX_FIRMWARE_NEPTUNE_DIRS += mediatek
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += \
	LICENCE.ralink_a_mediatek_company_firmware

LINUX_FIRMWARE_NEPTUNE_DIRS += qca qcom
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += LICENSE.qcom

LINUX_FIRMWARE_NEPTUNE_DIRS += rtw88 rtlwifi
LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES += LICENCE.rtlwifi_firmware.txt

# Some license files may be listed more than once, so we have to remove
# duplicates
LINUX_FIRMWARE_NEPTUNE_LICENSE_FILES = \
	$(sort $(LINUX_FIRMWARE_NEPTUNE_ALL_LICENSE_FILES))

define LINUX_FIRMWARE_NEPTUNE_BUILD_CMDS
	mkdir -p $(@D)/kernel/x86/microcode
	cat $(@D)/amd-ucode/microcode_amd*.bin > \
		$(@D)/kernel/x86/microcode/AuthenticAMD.bin

	# Reproducibility: strip the inode and device numbers from the cpio archive
	cd $(@D) && \
		echo kernel/x86/microcode/AuthenticAMD.bin | \
		bsdtar --uid 0 --gid 0 -cnf - -T - | \
		bsdtar --null -cf - --format=newc @- > $(@D)/amd-ucode.img
endef

LINUX_FIRMWARE_NEPTUNE_INSTALL_TARGET = YES
define LINUX_FIRMWARE_NEPTUNE_INSTALL_TARGET_CMDS
	mkdir -p $(TARGET_DIR)/lib/firmware
	cd $(@D) && \
		$(TAR) cf install.tar $(sort $(LINUX_FIRMWARE_NEPTUNE_FILES) $(LINUX_FIRMWARE_NEPTUNE_DIRS)) && \
		$(TAR) xf install.tar -C $(TARGET_DIR)/lib/firmware
endef

LINUX_FIRMWARE_NEPTUNE_INSTALL_IMAGES = YES
define LINUX_FIRMWARE_NEPTUNE_INSTALL_IMAGES_CMDS
	$(INSTALL) -D -m 0644 $(@D)/amd-ucode.img \
		$(BINARIES_DIR)/boot_part/amd-ucode.img
endef

$(eval $(generic-package))
