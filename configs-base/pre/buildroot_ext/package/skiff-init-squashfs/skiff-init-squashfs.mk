################################################################################
#
# skiff-init-squashfs
#
################################################################################

SKIFF_INIT_SQUASHFS_INSTALL_IMAGES = YES

define SKIFF_INIT_SQUASHFS_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) -static -o $(@D)/skiff-init-squashfs \
		$(SKIFF_INIT_SQUASHFS_PKGDIR)/skiff-init-squashfs.c
endef

define SKIFF_INIT_SQUASHFS_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/skiff-init
	$(INSTALL) -m 755 -D $(@D)/skiff-init-squashfs $(BINARIES_DIR)/skiff-init/skiff-init-squashfs
endef

$(eval $(generic-package))
