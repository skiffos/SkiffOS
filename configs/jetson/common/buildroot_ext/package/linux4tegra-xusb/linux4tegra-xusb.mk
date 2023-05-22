################################################################################
#
# linux4tegra-xusb
#
################################################################################

LINUX4TEGRA_XUSB_VERSION = 35.3.1
LINUX4TEGRA_XUSB_SITE = https://developer.download.nvidia.com/embedded/L4T/r35_Release_v3.1
LINUX4TEGRA_XUSB_SOURCE = overlay_xusb_$(LINUX4TEGRA_XUSB_VERSION).tbz2

LINUX4TEGRA_XUSB_LICENSE = NVIDIA Software License
LINUX4TEGRA_XUSB_LICENSE_FILES = license.txt
LINUX4TEGRA_XUSB_DEPENDENCIES = linux4tegra

LINUX4TEGRA_XUSB_INSTALL_IMAGES = YES

LINUX4TEGRA_XUSB_RSYNC = \
	rsync -a --ignore-times $(RSYNC_VCS_EXCLUSIONS) \
		--chmod=u=rwX,go=rX --exclude .empty --exclude '*~' \
		--keep-dirlinks --exclude=ld.so.conf.d --exclude=ld.so.conf

define LINUX4TEGRA_XUSB_INSTALL_IMAGES_CMDS
	# symlink to linux4tegra-xusb
	ln -fsn $(@D) $(BINARIES_DIR)/linux4tegra-xusb
	# override files in linux4tegra
	$(LINUX4TEGRA_XUSB_RSYNC) $(@D)/ $(BINARIES_DIR)/linux4tegra/
endef

$(eval $(generic-package))
