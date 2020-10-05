################################################################################
#
# skiff-core-gentoo
#
################################################################################

SKIFF_CORE_GENTOO_DEPENDENCIES = skiff-core skiff-core-defconfig

# Select the subdir based on the architecture.
SKIFF_CORE_GENTOO_COREENV_NAME = amd64
ifeq ($(BR2_arm),y)
SKIFF_CORE_GENTOO_COREENV_NAME = arm
endif
ifeq ($(BR2_aarch64),y)
SKIFF_CORE_GENTOO_COREENV_NAME = arm64
endif

define SKIFF_CORE_GENTOO_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-gentoo
	cp -r $(SKIFF_CORE_GENTOO_PKGDIR)/coreenv-$(SKIFF_CORE_GENTOO_COREENV_NAME)/* \
		$(TARGET_DIR)/opt/skiff/coreenv/skiff-core-gentoo/
	$(INSTALL) -m 0644 $(SKIFF_CORE_GENTOO_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_GENTOO_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_GENTOO_INSTALL_COREENV

$(eval $(generic-package))
