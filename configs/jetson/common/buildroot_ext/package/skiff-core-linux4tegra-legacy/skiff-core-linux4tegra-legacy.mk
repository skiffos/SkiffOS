################################################################################
#
# skiff-core-linux4tegra-legacy
#
################################################################################

SKIFF_CORE_LINUX4TEGRA_LEGACY_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_LINUX4TEGRA_LEGACY_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-linux4tegra-legacy
	cp -r $(SKIFF_CORE_LINUX4TEGRA_LEGACY_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-linux4tegra-legacy/
	$(INSTALL) -m 0644 $(SKIFF_CORE_LINUX4TEGRA_LEGACY_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_LINUX4TEGRA_LEGACY_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_LINUX4TEGRA_LEGACY_INSTALL_COREENV

$(eval $(generic-package))
