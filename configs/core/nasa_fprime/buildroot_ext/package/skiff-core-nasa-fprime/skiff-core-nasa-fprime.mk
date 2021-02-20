################################################################################
#
# skiff-core-nasa-fprime
#
################################################################################

SKIFF_CORE_NASA_FPRIME_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_NASA_FPRIME_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-nasa-fprime
	cp -r $(SKIFF_CORE_NASA_FPRIME_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-nasa-fprime/
	$(INSTALL) -m 0644 $(SKIFF_CORE_NASA_FPRIME_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_NASA_FPRIME_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_NASA_FPRIME_INSTALL_COREENV

$(eval $(generic-package))
