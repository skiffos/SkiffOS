################################################################################
#
# libnvidia-container
#
################################################################################

LIBNVIDIA_CONTAINER_VERSION = 1.2.0
LIBNVIDIA_CONTAINER_SITE = $(call github,NVIDIA,libnvidia-container,v$(LIBNVIDIA_CONTAINER_VERSION))
LIBNVIDIA_CONTAINER_LICENSE = Apache-2.0
LIBNVIDIA_CONTAINER_LICENSE_FILES = LICENSE

LIBNVIDIA_CONTAINER_DEPENDENCIES = elfutils libcap libtirpc nvidia-modprobe \
	host-pkgconf host-elfutils host-libcap

LIBNVIDIA_CONTAINER_MAKE_OPTS = \
	CFLAGS="$(TARGET_CFLAGS) -D_GNU_SOURCE" \
	OBJCPY="$(TARGET_OBJCOPY)" \
	RPCGEN="$(HOST_DIR)/bin/rpcgen" \
	WITH_LIBELF=yes \
	WITH_TIRPC=no

ifeq ($(BR2_PACKAGE_LIBSECCOMP),y)
LIBNVIDIA_CONTAINER_MAKE_OPTS += WITH_SECCOMP=yes
LIBNVIDIA_CONTAINER_DEPENDENCIES += libseccomp
else
LIBNVIDIA_CONTAINER_MAKE_OPTS += WITH_SECCOMP=no
endif

define LIBNVIDIA_CONTAINER_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		$(TARGET_CONFIGURE_OPTS) \
		$(LIBNVIDIA_CONTAINER_MAKE_OPTS) \
		shared tools
endef

define LIBNVIDIA_CONTAINER_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		$(TARGET_CONFIGURE_OPTS) \
		$(LIBNVIDIA_CONTAINER_MAKE_OPTS) \
		DESTDIR="$(TARGET_DIR)" \
		install
endef

$(eval $(generic-package))
