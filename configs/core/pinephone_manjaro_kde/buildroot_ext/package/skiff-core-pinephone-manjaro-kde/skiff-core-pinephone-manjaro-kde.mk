################################################################################
#
# skiff-core-pinephone-manjaro-kde
#
################################################################################

SKIFF_CORE_PINEPHONE_MANJARO_KDE_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_PINEPHONE_MANJARO_KDE_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-pinephone-manjaro-kde
	cp -r $(SKIFF_CORE_PINEPHONE_MANJARO_KDE_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-pinephone-manjaro-kde/
	$(INSTALL) -m 0644 $(SKIFF_CORE_PINEPHONE_MANJARO_KDE_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_PINEPHONE_MANJARO_KDE_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_PINEPHONE_MANJARO_KDE_INSTALL_COREENV

$(eval $(generic-package))
