################################################################################
#
# nvidia-modprobe
#
################################################################################

NVIDIA_MODPROBE_VERSION = 450.57
NVIDIA_MODPROBE_SITE = $(call github,NVIDIA,nvidia-modprobe,$(NVIDIA_MODPROBE_VERSION))
NVIDIA_MODPROBE_LICENSE = GPL-2
NVIDIA_MODPROBE_LICENSE_FILES = COPYING

NVIDIA_MODPROBE_DEPENDENCIES = host-pkgconf
NVIDIA_MODPROBE_INSTALL_STAGING = YES

define NVIDIA_MODPROBE_BUILD_CMDS
	mkdir -p $(@D)/bin
	$(TARGET_MAKE_ENV) $(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-I $(@D)/common-utils -I $(@D)/modprobe-utils \
		-o $(@D)/bin/nvidia-modprobe \
		-DNV_LINUX=true -DPROGRAM_NAME=\"nvidia-modprobe\" \
		-DNVIDIA_VERSION=\"$(NVIDIA_MODPROBE_VERSION)\" \
		$(@D)/nvidia-modprobe.c $(@D)/modprobe-utils/nvidia-modprobe-utils.c \
		$(@D)/modprobe-utils/pci-sysfs.c $(@D)/common-utils/common-utils.c \
		$(@D)/common-utils/msg.c $(@D)/common-utils/nvgetopt.c
endef

define NVIDIA_MODPROBE_INSTALL_STAGING_CMDS
	$(INSTALL) -D -m 644 $(@D)/modprobe-utils/nvidia-modprobe-utils.h \
		$(STAGING_DIR)/usr/include/nvidia-modprobe-utils/nvidia-modprobe-utils.h
	$(INSTALL) -D -m 644 $(@D)/modprobe-utils/pci-enum.h \
		$(STAGING_DIR)/usr/include/nvidia-modprobe-utils/pci-enum.h
	$(INSTALL) -D -m 644 $(@D)/common-utils/common-utils.h \
		$(STAGING_DIR)/usr/include/nvidia-modprobe-utils/nvidia-common-utils.h
	$(INSTALL) -D -m 644 $(@D)/common-utils/msg.h \
		$(STAGING_DIR)/usr/include/nvidia-modprobe-utils/msg.h
	$(INSTALL) -D -m 644 $(@D)/common-utils/nvgetopt.h \
		$(STAGING_DIR)/usr/include/nvidia-modprobe-utils/nvgetopt.h
endef

define NVIDIA_MODPROBE_INSTALL_TARGET_CMDS
	$(INSTALL) -m 0755 $(@D)/bin/nvidia-modprobe \
		$(TARGET_DIR)/usr/bin/nvidia-modprobe
endef

$(eval $(generic-package))
