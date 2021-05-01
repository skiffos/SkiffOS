################################################################################
#
# skiff-core-alpine
#
################################################################################

SKIFF_CORE_ALPINE_DEPENDENCIES = skiff-core skiff-core-defconfig

define SKIFF_CORE_ALPINE_INSTALL_COREENV
	mkdir -p $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-alpine
	cd $(TARGET_DIR)/opt/skiff/coreenv/skiff-core-alpine ; \
		cp -r $(SKIFF_CORE_ALPINE_PKGDIR)/coreenv/* ./ ;\
		$(INSTALL) -m 0644 $(SKIFF_CORE_ALPINE_PKGDIR)/coreenv-defconfig.yaml \
			../defconfig.yaml ; \
		touch ../.overridden
endef

SKIFF_CORE_ALPINE_POST_INSTALL_TARGET_HOOKS += SKIFF_CORE_ALPINE_INSTALL_COREENV

$(eval $(generic-package))
