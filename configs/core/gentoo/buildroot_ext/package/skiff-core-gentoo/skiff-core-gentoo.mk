################################################################################
#
# skiff-core-gentoo
#
################################################################################

SKIFF_CORE_GENTOO_DEPENDENCIES = skiff-core skiff-core-defconfig

# Select the distro based on the architecture.

# amd64 (default)
SKIFF_CORE_GENTOO_COREENV_ARCH = amd64

# arm
ifeq ($(BR2_arm),y)
SKIFF_CORE_GENTOO_COREENV_ARCH = arm

# armv6 (default)
SKIFF_CORE_GENTOO_COREENV_MICROARCH = armv6j
SKIFF_CORE_GENTOO_COREENV_SUFFIX = _hardfp
SKIFF_CORE_GENTOO_COREENV_SUBPROFILE = armv6j/systemd

# armv5
ifeq ($(BR2_ARM_CPU_ARMV5),y)
SKIFF_CORE_GENTOO_COREENV_MICROARCH = armv5tel
SKIFF_CORE_GENTOO_COREENV_SUFFIX = none
SKIFF_CORE_GENTOO_COREENV_SUBPROFILE = armv5te/systemd
endif

# armv7a (default)
ifeq ($(BR2_ARM_CPU_ARMV7A),y)
SKIFF_CORE_GENTOO_COREENV_MICROARCH = armv7a
SKIFF_CORE_GENTOO_COREENV_SUFFIX = _hardfp
SKIFF_CORE_GENTOO_COREENV_SUBPROFILE = armv7a/systemd
endif

endif

# aarch64 / arm64
ifeq ($(BR2_aarch64),y)
SKIFF_CORE_GENTOO_COREENV_ARCH = arm64
SKIFF_CORE_GENTOO_COREENV_MICROARCH = arm64
endif

SKIFF_CORE_GENTOO_COREENV_DIST = \
	http://distfiles.gentoo.org/releases/$(SKIFF_CORE_GENTOO_COREENV_ARCH)/autobuilds

# default microarch to equal arch
ifeq ($(SKIFF_CORE_GENTOO_COREENV_MICROARCH),)
SKIFF_CORE_GENTOO_COREENV_MICROARCH = $(SKIFF_CORE_GENTOO_COREENV_ARCH)
endif

# configure the CFLAGS in Gentoo according to the Skiff CFLAGS
# ... but only if there is some reason to (target optimization flags set)
ifneq ($(BR2_TARGET_OPTIMIZATION),)
SKIFF_CORE_GENTOO_CFLAGS = -O2 -fomit-frame-pointer -pipe
SKIFF_CORE_GENTOO_CFLAGS += $(call qstrip,$(BR2_TARGET_OPTIMIZATION))
endif

define SKIFF_CORE_GENTOO_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-gentoo
	cd $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-gentoo ; \
		cp -r $(SKIFF_CORE_GENTOO_PKGDIR)/coreenv/* ./ ;\
		$(INSTALL) -m 0644 $(SKIFF_CORE_GENTOO_PKGDIR)/coreenv-defconfig.yaml \
			../defconfig.yaml ; \
    if [ -n "$(SKIFF_CORE_GENTOO_CFLAGS)" ]; then \
		  $(SED) "/COMMON_FLAGS=/c\COMMON_FLAGS=\"$(SKIFF_CORE_GENTOO_CFLAGS)\"" \
			  make.conf; \
		fi; \
		bash ./mkoverride.sh ARCH $(SKIFF_CORE_GENTOO_COREENV_ARCH); \
		bash ./mkoverride.sh MICROARCH $(SKIFF_CORE_GENTOO_COREENV_MICROARCH); \
		bash ./mkoverride.sh SUBPROFILE $(SKIFF_CORE_GENTOO_COREENV_SUBPROFILE); \
		bash ./mkoverride.sh SUFFIX $(SKIFF_CORE_GENTOO_COREENV_SUFFIX); \
		bash ./mkoverride.sh DIST "$(SKIFF_CORE_GENTOO_COREENV_DIST)"; \
		touch ../.overridden
endef

SKIFF_CORE_GENTOO_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_GENTOO_INSTALL_COREENV

$(eval $(generic-package))
