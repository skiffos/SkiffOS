################################################################################
#
# skiff-init-squashfs
#
################################################################################

SKIFF_INIT_SQUASHFS_INSTALL_IMAGES = YES

SKIFF_INIT_SQUASHFS_CFLAGS = $(TARGET_CFLAGS) -static

ifeq ($(BR2_PACKAGE_SKIFF_INIT_SQUASHFS_NO_MOVE_MOUNTPOINT_ROOT),y)
SKIFF_INIT_SQUASHFS_CFLAGS += -DNO_MOVE_MOUNTPOINT_ROOT
endif

define SKIFF_INIT_SQUASHFS_BUILD_CMDS
	$(TARGET_CC) $(SKIFF_INIT_SQUASHFS_CFLAGS) -o $(@D)/skiff-init-squashfs \
		$(SKIFF_INIT_SQUASHFS_PKGDIR)/skiff-init-squashfs.c
endef

define SKIFF_INIT_SQUASHFS_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/skiff-init
	$(INSTALL) -m 755 -D $(@D)/skiff-init-squashfs \
		$(BINARIES_DIR)/skiff-init/skiff-init-squashfs
endef

$(eval $(generic-package))
