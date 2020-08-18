################################################################################
#
# argononed
#
################################################################################

ARGONONED_VERSION = c878d737bf2091027c704a157b0f95b67042bbc4
ARGONONED_SITE = $(call github,paralin,argonone,$(ARGONONED_VERSION))

ARGONONED_LICENSE = GPL-3.0+
ARGONONED_LICENSE_FILES = LICENSE

define ARGONONED_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(@D)/argonone-config \
		$(TARGET_DIR)/usr/bin/argonone-config
	$(INSTALL) -D -m 0666 $(@D)/argononed.conf $(TARGET_DIR)/etc/argononed.conf
	$(INSTALL) -D -m 0755 $(@D)/argononed.py \
		$(TARGET_DIR)/opt/argonone/bin/argononed.py
endef

define ARGONONED_INSTALL_INIT_SYSTEMD
	$(INSTALL) -D -m 0644 $(@D)/argononed.service \
		$(TARGET_DIR)/usr/lib/systemd/system/argononed.service
	$(INSTALL) -D -m 0755 $(@D)/argononed-poweroff.py \
		$(TARGET_DIR)/usr/lib/systemd/system-shutdown/argononed-poweroff.py
endef

$(eval $(generic-package))
