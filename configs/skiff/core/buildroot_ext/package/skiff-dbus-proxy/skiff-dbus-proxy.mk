################################################################################
#
# skiff-dbus-proxy
#
################################################################################

SKIFF_DBUS_PROXY_VERSION = a40b54bd36a79b6f67153c6dac66d63190124778
SKIFF_DBUS_PROXY_SITE = $(call github,skiffos,skiff-dbus-proxy,$(SKIFF_DBUS_PROXY_VERSION))
SKIFF_DBUS_PROXY_LICENSE = MIT
SKIFF_DBUS_PROXY_LICENSE_FILES = LICENSE
SKIFF_DBUS_PROXY_DEPENDENCIES = host-pkgconf systemd

define SKIFF_DBUS_PROXY_INSTALL_WRAPPER
	$(INSTALL) -D -m 0755 \
		$(SKIFF_DBUS_PROXY_PKGDIR)/skiff-dbus-proxy.sh \
		$(TARGET_DIR)/opt/skiff/scripts/skiff-dbus-proxy.sh
endef

SKIFF_DBUS_PROXY_POST_INSTALL_TARGET_HOOKS += SKIFF_DBUS_PROXY_INSTALL_WRAPPER

define SKIFF_DBUS_PROXY_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 \
		$(SKIFF_DBUS_PROXY_PKGDIR)/skiff-dbus-proxy.service \
		$(TARGET_DIR)/usr/lib/systemd/system/skiff-dbus-proxy.service
	mkdir -p $(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants
	ln -sf ../skiff-dbus-proxy.service \
		$(TARGET_DIR)/usr/lib/systemd/system/multi-user.target.wants/skiff-dbus-proxy.service
endef


$(eval $(meson-package))
