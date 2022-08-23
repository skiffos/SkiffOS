################################################################################
#
# skiff-core-fedora
#
################################################################################

SKIFF_CORE_FEDORA_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_FEDORA_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-fedora
	cp -r $(SKIFF_CORE_FEDORA_PKGDIR)/coreenv/* $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-fedora/
	$(INSTALL) -m 0644 $(SKIFF_CORE_FEDORA_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_FEDORA_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_FEDORA_INSTALL_COREENV

$(eval $(generic-package))
