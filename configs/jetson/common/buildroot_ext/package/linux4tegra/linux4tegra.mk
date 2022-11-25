################################################################################
#
# linux4tegra
#
################################################################################

LINUX4TEGRA_VERSION = 35.1.0
LINUX4TEGRA_SITE = https://developer.nvidia.com/embedded/l4t/r35_release_v1.0/release
LINUX4TEGRA_SOURCE = jetson_linux_r$(LINUX4TEGRA_VERSION)_aarch64.tbz2

LINUX4TEGRA_LICENSE = NVIDIA Software License, GPL-2.0, LGPL, Apache-2.0, MIT
LINUX4TEGRA_LICENSE_FILES = \
	bootloader/LICENSE \
	bootloader/LICENSE.chkbdinfo \
	bootloader/LICENSE.mkbctpart \
	bootloader/LICENSE.mkbootimg \
	bootloader/LICENSE.mkgpt \
	bootloader/LICENSE.mksparse \
	bootloader/LICENSE.tegraopenssl \
	nv_tegra/nvidia_configs/opt/nvidia/l4t-usb-device-mode/LICENSE.filesystem.img \
	nv_tegra/LICENSE.libtegrav4l2 \
	nv_tegra/LICENSE.libnvcam_imageencoder \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libvulkan1 \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnvargus \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnvv4lconvert \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libtegrav4l2 \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnvv4l2 \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.nvdla \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.cypress_wifibt \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.minigbm \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnvjpeg \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.brcm_patchram_plus \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnvcam_imageencoder \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnvtracebuf \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.realtek_8822ce_wifibt \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.tegra_sensors \
	nv_tegra/nvidia_drivers/usr/share/doc/nvidia-tegra/LICENSE.libnveventlib \
	nv_tegra/LICENSE.libnveventlib \
	nv_tegra/LICENSE.libnvscf \
	nv_tegra/LICENSE.libnvargus \
	nv_tegra/LICENSE.minigbm \
	nv_tegra/LICENSE.wayland-ivi-extension \
	nv_tegra/nv_sample_apps/LICENSE.gst-nvvideo4linux2 \
	nv_tegra/nv_sample_apps/LICENSE.gstvideocuda \
	nv_tegra/nv_sample_apps/LICENSE.gst-openmax \
	nv_tegra/nv_sample_apps/LICENSE.libgstnvdrmvideosink \
	nv_tegra/nv_sample_apps/LICENSE.libgstnvvideosinks \
	nv_tegra/LICENSE \
	nv_tegra/LICENSE.weston-data \
	nv_tegra/LICENSE.libnvtracebuf \
	nv_tegra/LICENSE.weston \
	nv_tegra/LICENSE.nvdla \
	nv_tegra/LICENSE.l4t-usb-device-mode-filesystem.img \
	nv_tegra/LICENSE.brcm_patchram_plus

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
		--keep-dirlinks --exclude=ld.so.conf.d

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
endef

$(eval $(generic-package))
