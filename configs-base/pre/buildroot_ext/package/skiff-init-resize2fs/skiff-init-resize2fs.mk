################################################################################
#
# skiff-init-resize2fs
#
# based on e2fsprogs
#
################################################################################

SKIFF_INIT_RESIZE2FS_DEPENDENCIES = host-pkgconf e2fsprogs-build

SKIFF_INIT_RESIZE2FS_INSTALL_TARGET = NO
SKIFF_INIT_RESIZE2FS_INSTALL_STAGING = NO
SKIFF_INIT_RESIZE2FS_INSTALL_IMAGES = YES

# build the static binary
define SKIFF_INIT_RESIZE2FS_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(E2FSPROGS_SRCDIR)/resize resize2fs.static
endef

define SKIFF_INIT_RESIZE2FS_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/skiff-init
	$(INSTALL) -m 755 -D $(E2FSPROGS_SRCDIR)/resize/resize2fs.static \
		 $(BINARIES_DIR)/skiff-init/resize2fs
endef

$(eval $(generic-package))
