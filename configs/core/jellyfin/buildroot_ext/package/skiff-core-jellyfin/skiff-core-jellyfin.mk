################################################################################
#
# skiff-core-jellyfin
#
################################################################################

SKIFF_CORE_JELLYFIN_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_JELLYFIN_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-jellyfin
	$(INSTALL) -m 0644 $(SKIFF_CORE_JELLYFIN_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_JELLYFIN_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_JELLYFIN_INSTALL_COREENV

$(eval $(generic-package))
