################################################################################
#
# skiff-core-diet-pi
#
################################################################################

SKIFF_CORE_DIET_PI_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_DIET_PI_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-diet-pi
	cp -r $(SKIFF_CORE_DIET_PI_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-diet-pi/
	$(INSTALL) -m 0644 $(SKIFF_CORE_DIET_PI_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_DIET_PI_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_DIET_PI_INSTALL_COREENV

$(eval $(generic-package))
