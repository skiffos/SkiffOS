################################################################################
#
# skiff-core-fedora
#
################################################################################

ifeq ($(BR2_PACKAGE_SKIFF_CORE_FEDORA),y)
ifneq ($(BR2_PACKAGE_SKIFF_CORE_FEDORA_SUPPORTS),y)
ifeq ($(BR2_arm),y)
$(error "Fedora: support for ARMv7 was removed in release 37.")
else
$(error "Fedora: supports arm64, amd64, and riscv as of v37.")
endif
endif
endif

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
