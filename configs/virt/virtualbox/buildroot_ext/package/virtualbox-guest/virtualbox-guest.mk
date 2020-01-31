################################################################################
#
# virtualbox-guest
#
################################################################################

VIRTUALBOX_GUEST_VERSION = 6.1.2
VIRTUALBOX_GUEST_SITE = https://download.virtualbox.org/virtualbox/$(VIRTUALBOX_GUEST_VERSION)
VIRTUALBOX_GUEST_SOURCE = VirtualBox-$(VIRTUALBOX_GUEST_VERSION).tar.bz2
VIRTUALBOX_GUEST_LICENSE = GPL-2

define VIRTUALBOX_GUEST_EXTRACT_MODULES
	rm -rf $(@D)/vbox-guest-kmod || true
	$(@D)/src/VBox/Additions/linux/export_modules.sh \
		--folder $(@D)/vbox-guest-kmod
endef
VIRTUALBOX_GUEST_POST_EXTRACT_HOOKS += VIRTUALBOX_GUEST_EXTRACT_MODULES

VIRTUALBOX_GUEST_MODULE_SUBDIRS = vbox-guest-kmod

$(eval $(kernel-module))

define VIRTUALBOX_GUEST_BUILD_CMDS
	$(TARGET_CC) $(TARGET_CFLAGS) $(TARGET_LDFLAGS) \
		-D_GNU_SOURCE -DIN_RING3 \
		-I$(@D)/vbox-guest-kmod/vboxsf/include \
		-I$(@D)/vbox-guest-kmod/vboxsf \
		-o $(@D)/mount.vboxsf \
		$(@D)/src/VBox/Additions/linux/sharedfolders/vbsfmount.c \
		$(@D)/src/VBox/Additions/linux/sharedfolders/mount.vboxsf.c
endef

define VIRTUALBOX_GUEST_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/mount.vboxsf \
		$(TARGET_DIR)/usr/sbin/mount.vboxsf
endef

define VIRTUALBOX_GUEST_PERMISSIONS
	/usr/sbin/mount.vboxsf	f	0755	0	0	-	-	-	-	-
endef

$(eval $(generic-package))
