################################################################################
#
# skiff-core-nasa-cfs
#
################################################################################

SKIFF_CORE_NASA_CFS_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_NASA_CFS_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-nasa-cfs
	cp -r $(SKIFF_CORE_NASA_CFS_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-nasa-cfs/
	$(INSTALL) -m 0644 $(SKIFF_CORE_NASA_CFS_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_NASA_CFS_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_NASA_CFS_INSTALL_COREENV

$(eval $(generic-package))
