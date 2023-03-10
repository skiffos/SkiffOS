################################################################################
#
# linux4tegra
#
################################################################################

LINUX4TEGRA_VERSION = 35.2.1
LINUX4TEGRA_SITE = https://developer.download.nvidia.com/embedded/L4T/r35_Release_v2.1/release
LINUX4TEGRA_SOURCE = Jetson_Linux_R$(LINUX4TEGRA_VERSION)_aarch64.tbz2

LINUX4TEGRA_LICENSE = NVIDIA Software License, GPL-2.0, LGPL, Apache-2.0, MIT

LINUX4TEGRA_INSTALL_IMAGES = YES

define LINUX4TEGRA_EXTRACT_NVIDIA_DRIVERS
	@mkdir -p $(@D)/nv_tegra/nvidia_drivers
	$(call suitable-extractor,nvidia_drivers.tbz2) \
		$(@D)/nv_tegra/nvidia_drivers.tbz2 | \
		$(TAR) -C $(@D)/nv_tegra/nvidia_drivers $(TAR_OPTIONS) -
endef

LINUX4TEGRA_POST_EXTRACT_HOOKS += LINUX4TEGRA_EXTRACT_NVIDIA_DRIVERS

define LINUX4TEGRA_EXTRACT_NVIDIA_CONFIGS
	@mkdir -p $(@D)/nv_tegra/nvidia_configs
	$(call suitable-extractor,config.tbz2) \
		$(@D)/nv_tegra/config.tbz2 | \
		$(TAR) -C $(@D)/nv_tegra/nvidia_configs $(TAR_OPTIONS) -
endef

LINUX4TEGRA_POST_EXTRACT_HOOKS += LINUX4TEGRA_EXTRACT_NVIDIA_CONFIGS

define LINUX4TEGRA_EXTRACT_NVIDIA_TOOLS
	@mkdir -p $(@D)/nv_tegra/nvidia_tools
	$(call suitable-extractor,nv_tools.tbz2) \
		$(@D)/nv_tegra/nv_tools.tbz2 | \
		$(TAR) -C $(@D)/nv_tegra/nvidia_tools $(TAR_OPTIONS) -
endef

LINUX4TEGRA_POST_EXTRACT_HOOKS += LINUX4TEGRA_EXTRACT_NVIDIA_TOOLS

# symlink linux4tegra to the target dir.
define LINUX4TEGRA_INSTALL_IMAGES_CMDS
	ln -fsn $(@D) $(BINARIES_DIR)/linux4tegra
endef

LINUX4TEGRA_RSYNC = \
	rsync -a --ignore-times $(RSYNC_VCS_EXCLUSIONS) \
		--chmod=u=rwX,go=rX --exclude .empty --exclude '*~' \
		--keep-dirlinks --exclude=ld.so.conf.d --exclude=ld.so.conf

define LINUX4TEGRA_INSTALL_TARGET_CMDS
	# install nvidia_drivers
	$(LINUX4TEGRA_RSYNC) $(@D)/nv_tegra/nvidia_drivers/ $(TARGET_DIR)/
	# install nvidia_configs
	$(LINUX4TEGRA_RSYNC) $(@D)/nv_tegra/nvidia_configs/ $(TARGET_DIR)/
	# install nvidia_tools
	$(LINUX4TEGRA_RSYNC) $(@D)/nv_tegra/nvidia_tools/ $(TARGET_DIR)/
	# remove some unnecessary systemd units
	cd $(TARGET_DIR)/etc/systemd/system && rm \
		./sysinit.target.wants/nvfb-udev.service \
		./multi-user.target.wants/nv-l4t-bootloader-config.service
	# move some libraries
	rsync -av $(TARGET_DIR)/usr/lib/aarch64-linux-gnu/tegra/ $(TARGET_DIR)/usr/lib/
	rm -rf $(TARGET_DIR)/usr/lib/aarch64-linux-gnu/tegra
	rsync -av $(TARGET_DIR)/usr/lib/aarch64-linux-gnu/ $(TARGET_DIR)/usr/lib/
	rm -rf $(TARGET_DIR)/usr/lib/aarch64-linux-gnu
endef

$(eval $(generic-package))
