################################################################################
#
# nvidia-container-toolkit
#
################################################################################

NVIDIA_CONTAINER_TOOLKIT_VERSION = 1.2.1
NVIDIA_CONTAINER_TOOLKIT_SITE = $(call github,NVIDIA,nvidia-container-toolkit,v$(NVIDIA_CONTAINER_TOOLKIT_VERSION))

NVIDIA_CONTAINER_TOOLKIT_LICENSE = Apache-2.0
NVIDIA_CONTAINER_TOOLKIT_LICENSE_FILES = LICENSE

NVIDIA_CONTAINER_TOOLKIT_DEPENDENCIES = nvidia-container-runtime libnvidia-container

NVIDIA_CONTAINER_TOOLKIT_BUILD_TARGETS = github.com/NVIDIA/container-toolkit/pkg
NVIDIA_CONTAINER_TOOLKIT_BIN_NAME = nvidia-container-toolkit
NVIDIA_CONTAINER_TOOLKIT_TAGS = cgo static_build

define NVIDIA_CONTAINER_TOOLKIT_INSTALL_SUPPORT
	ln -fs /usr/bin/$(NVIDIA_CONTAINER_TOOLKIT_BIN_NAME) \
		$(TARGET_DIR)/usr/bin/nvidia-container-runtime-hook
	$(INSTALL) -D -m 644 $(@D)/oci-nvidia-hook.json \
		$(TARGET_DIR)/usr/share/containers/oci/hooks.d/oci-nvidia-hook.json
	$(INSTALL) -D -m 755 $(@D)/oci-nvidia-hook \
		$(TARGET_DIR)/usr/libexec/oci/hooks.d/oci-nvidia-hook
endef

NVIDIA_CONTAINER_TOOLKIT_POST_INSTALL_TARGET_HOOKS += NVIDIA_CONTAINER_TOOLKIT_INSTALL_SUPPORT

$(eval $(golang-package))
