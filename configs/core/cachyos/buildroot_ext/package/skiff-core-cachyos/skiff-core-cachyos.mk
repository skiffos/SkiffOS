################################################################################
#
# skiff-core-cachyos
#
################################################################################

SKIFF_CORE_CACHYOS_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_CACHYOS_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-cachyos
	cp -r $(SKIFF_CORE_CACHYOS_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-cachyos/
	$(INSTALL) -m 0644 $(SKIFF_CORE_CACHYOS_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_CACHYOS_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_CACHYOS_INSTALL_COREENV

$(eval $(generic-package))
