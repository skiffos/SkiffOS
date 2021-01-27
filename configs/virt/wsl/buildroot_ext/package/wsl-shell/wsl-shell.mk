################################################################################
#
# wsl-shell
#
################################################################################

WSL_SHELL_INSTALL_IMAGES = YES

WSL_SHELL_CFLAGS = $(TARGET_CFLAGS) -static

ifneq ($(BR2_PACKAGE_WSL_SHELL_CHROOT_TARGET),y)
WSL_SHELL_CFLAGS += -DNO_CHROOT_TARGET
endif

ifeq ($(BR2_PACKAGE_WSL_SHELL_RUN_SKIFF_INIT),y)
WSL_SHELL_CFLAGS += -DRUN_SKIFF_INIT
endif

ifeq ($(BR2_PACKAGE_WSL_SHELL_NO_DROP_ENV),y)
WSL_SHELL_CFLAGS += -DNO_DROP_ENV
endif

define WSL_SHELL_BUILD_CMDS
	$(TARGET_CC) $(WSL_SHELL_CFLAGS) -o $(@D)/wsl-shell \
		$(WSL_SHELL_PKGDIR)/wsl-shell.c
endef

define WSL_SHELL_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/skiff-init
	$(INSTALL) -m 755 -D $(@D)/wsl-shell \
		$(BINARIES_DIR)/skiff-init/wsl-shell
endef

$(eval $(generic-package))
