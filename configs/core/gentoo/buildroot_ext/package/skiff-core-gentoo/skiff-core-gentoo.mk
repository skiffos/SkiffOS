################################################################################
#
# skiff-core-gentoo
#
################################################################################

SKIFF_CORE_GENTOO_DEPENDENCIES = skiff-core skiff-core-defconfig

# Select the distro based on the architecture.
# see http://distfiles.gentoo.org/releases/{ARCH}/autobuilds
# note: these may become unavailable over time.

# amd64 (default)
SKIFF_CORE_GENTOO_COREENV_ARCH = amd64
SKIFF_CORE_GENTOO_COREENV_STAGE3PATH = autobuilds/20201206T214503Z/stage3-amd64-systemd-20201206T214503Z.tar.xz

# arm
ifeq ($(BR2_arm),y)
SKIFF_CORE_GENTOO_COREENV_ARCH = arm
SKIFF_CORE_GENTOO_COREENV_STAGE3PATH = autobuilds/20200509T210605Z/stage3-armv6j_hardfp-20200509T210605Z.tar.xz

ifeq ($(BR2_ARM_CPU_ARMV5),y)
SKIFF_CORE_GENTOO_COREENV_STAGE3PATH = autobuilds/20200509T210605Z/stage3-armv5tel-20200509T210605Z.tar.xz
endif
ifeq ($(BR2_ARM_CPU_ARMV7A),y)
SKIFF_CORE_GENTOO_COREENV_STAGE3PATH = autobuilds/20200509T210605Z/stage3-armv7a_hardfp-20200509T210605Z.tar.xz
endif

endif

# aarch64
ifeq ($(BR2_aarch64),y)
SKIFF_CORE_GENTOO_COREENV_ARCH = arm64
SKIFF_CORE_GENTOO_COREENV_STAGE3PATH = autobuilds/current-stage3-arm64-systemd/stage3-arm64-systemd-20201216T203511Z.tar.xz
endif

SKIFF_CORE_GENTOO_COREENV_DIST = \
	http://distfiles.gentoo.org/releases/$(SKIFF_CORE_GENTOO_COREENV_ARCH)

define SKIFF_CORE_GENTOO_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-gentoo
	cd $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-gentoo ; \
		cp -r $(SKIFF_CORE_GENTOO_PKGDIR)/coreenv/* ./ ;\
		$(INSTALL) -m 0644 $(SKIFF_CORE_GENTOO_PKGDIR)/coreenv-defconfig.yaml \
			../defconfig.yaml ; \
		echo "ARCH=\"$(SKIFF_CORE_GENTOO_COREENV_ARCH)\"" >> ./overrides.sh ; \
		echo "DIST=\"$(SKIFF_CORE_GENTOO_COREENV_DIST)\"" >> ./overrides.sh ; \
		echo "STAGE3PATH=\"$(SKIFF_CORE_GENTOO_COREENV_STAGE3PATH)\"" >> \
			./overrides.sh ; \
		touch ../.overridden
endef

SKIFF_CORE_GENTOO_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_GENTOO_INSTALL_COREENV

$(eval $(generic-package))
