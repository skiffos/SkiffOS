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

LIBNVIDIA_CONTAINER_INCLUDE_DIRS += \
	-I$(HOST_DIR)/include -I$(STAGING_DIR)/usr/include \
	-I$(STAGING_DIR)/usr/include/nvidia-modprobe-utils

LIBNVIDIA_CONTAINER_MAKE_OPTS = \
	AR="$(TARGET_AR)" STRIP="$(TARGET_STRIP)" \
	CC="$(TARGET_CC)" CFLAGS="$(TARGET_CFLAGS) \
	$(LIBNVIDIA_CONTAINER_INCLUDE_DIRS) -D_GNU_SOURCE" \
	CXX="$(TARGET_CXX)" CPPFLAGS="$(TARGET_CXXFLAGS)" \
	LD="$(TARGET_LD)" LDFLAGS="$(TARGET_LDFLAGS)" \
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
		$(LIBNVIDIA_CONTAINER_MAKE_OPTS) \
		shared tools
endef

define LIBNVIDIA_CONTAINER_INSTALL_STAGING_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		$(LIBNVIDIA_CONTAINER_MAKE_OPTS) \
		DESTDIR="$(STAGING_DIR)" \
		install
endef

define LIBNVIDIA_CONTAINER_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) \
		$(LIBNVIDIA_CONTAINER_MAKE_OPTS) \
		DESTDIR="$(TARGET_DIR)" \
		install
endef

$(eval $(generic-package))
