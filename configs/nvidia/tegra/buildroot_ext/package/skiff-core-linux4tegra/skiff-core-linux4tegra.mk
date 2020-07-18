################################################################################
#
# skiff-core-linux4tegra
#
################################################################################

SKIFF_CORE_LINUX4TEGRA_DEPENDENCIES = skiff-core

# Select which dockerfile to use.
# Note: additional for other base images will be added.
SKIFF_CORE_LINUX4TEGRA_DOCKERFILE = Dockerfile

# define SKIFF_CORE_LINUX4TEGRA_INSTALL_TARGET_CMDS
define SKIFF_CORE_LINUX4TEGRA_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv
	$(INSTALL) -m 0644 $(SKIFF_CORE_LINUX4TEGRA_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	sed -i -e "s/COREENV_DOCKERFILE/$(SKIFF_CORE_LINUX4TEGRA_DOCKERFILE)/g" \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-linux4tegra
	cp -r $(SKIFF_CORE_LINUX4TEGRA_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-linux4tegra/
endef

SKIFF_CORE_LINUX4TEGRA_FINALIZE_HOOKS += SKIFF_CORE_LINUX4TEGRA_INSTALL_COREENV

$(eval $(generic-package))
