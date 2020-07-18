################################################################################
#
# nvidia-container-runtime
#
################################################################################

NVIDIA_CONTAINER_RUNTIME_VERSION = 3.3.0
NVIDIA_CONTAINER_RUNTIME_SITE = $(call github,NVIDIA,nvidia-container-runtime,v$(NVIDIA_CONTAINER_RUNTIME_VERSION))
NVIDIA_CONTAINER_RUNTIME_LICENSE = Apache-2.0
NVIDIA_CONTAINER_RUNTIME_LICENSE_FILES = LICENSE

NVIDIA_CONTAINER_RUNTIME_LDFLAGS = -X main.gitCommit=$(NVIDIA_CONTAINER_RUNTIME_VERSION)
NVIDIA_CONTAINER_RUNTIME_TAGS = cgo static_build

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
NVIDIA_CONTAINER_RUNTIME_TAGS += seccomp
NVIDIA_CONTAINER_RUNTIME_DEPENDENCIES += libseccomp host-pkgconf
endif

NVIDIA_CONTAINER_RUNTIME_GOMOD = github.com/NVIDIA/nvidia-container-runtime
NVIDIA_CONTAINER_RUNTIME_BUILD_TARGETS = github.com/NVIDIA/nvidia-container-runtime/src
NVIDIA_CONTAINER_RUNTIME_BIN_NAME = nvidia-container-runtime

define NVIDIA_CONTAINER_RUNTIME_INSTALL_SUPPORT
	$(INSTALL) -D -m 644 $(NVIDIA_CONTAINER_RUNTIME_PKGDIR)/config.toml \
		$(TARGET_DIR)/etc/nvidia-container-runtime/config.toml
	$(INSTALL) -D -m 644 $(NVIDIA_CONTAINER_RUNTIME_PKGDIR)/daemon.json \
		$(TARGET_DIR)/etc/docker/daemon.json
endef

NVIDIA_CONTAINER_RUNTIME_POST_INSTALL_TARGET_HOOKS += NVIDIA_CONTAINER_RUNTIME_INSTALL_SUPPORT

$(eval $(golang-package))
