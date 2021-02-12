################################################################################
#
# skiff-core-pinebook-gentoo
#
################################################################################

SKIFF_CORE_PINEBOOK_GENTOO_DEPENDENCIES = skiff-core \
	skiff-core-defconfig skiff-core-gentoo

# override files from skiff-core-gentoo
define SKIFF_CORE_PINEBOOK_GENTOO_INSTALL_COREENV
	$(INSTALL) -m 0644 $(SKIFF_CORE_PINEBOOK_GENTOO_PKGDIR)/coreenv-defconfig.yaml \
		$(TARGET_DIR)/opt/skiff/coreenv/defconfig.yaml
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_PINEBOOK_GENTOO_POST_INSTALL_TARGET_HOOKS += \
	SKIFF_CORE_PINEBOOK_GENTOO_INSTALL_COREENV

$(eval $(generic-package))
