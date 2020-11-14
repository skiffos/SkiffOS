################################################################################
#
# skiff-core-nixos-xfce
#
################################################################################

SKIFF_CORE_NIXOS_XFCE_DEPENDENCIES = skiff-core \
	skiff-core-defconfig skiff-core-nixos

# override files from skiff-core-nixos
define SKIFF_CORE_NIXOS_XFCE_INSTALL_COREENV
	cp -r $(SKIFF_CORE_NIXOS_XFCE_PKGDIR)/coreenv/* \
		$(TARGET_DIR)/opt/skiff/coreenv/skiff-core-nixos/
	touch $(TARGET_DIR)/opt/skiff/coreenv/.overridden
endef

SKIFF_CORE_NIXOS_XFCE_POST_INSTALL_TARGET_HOOKS += \
	SKIFF_CORE_NIXOS_XFCE_INSTALL_COREENV

$(eval $(generic-package))
