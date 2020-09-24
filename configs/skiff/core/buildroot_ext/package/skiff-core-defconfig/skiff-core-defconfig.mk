################################################################################
#
# skiff-core-defconfig
#
################################################################################

SKIFF_CORE_DEFCONFIG_DEPENDENCIES = skiff-core

define SKIFF_CORE_DEFCONFIG_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/base
	cp -r $(SKIFF_CORE_DEFCONFIG_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/base
	$(INSTALL) -m 0644 $(SKIFF_CORE_DEFCONFIG_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
endef

SKIFF_CORE_DEFCONFIG_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_DEFCONFIG_INSTALL_COREENV

$(eval $(generic-package))
