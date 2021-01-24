################################################################################
#
# wslu
#
################################################################################

WSLU_VERSION = v3.2.1
WSLU_SITE = $(call github,wslutilities,wslu,$(WSLU_VERSION))
WSLU_LICENSE = GPL-3.0+
WSLU_LICENSE_FILES = LICENSE

define WSLU_BUILD_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) all
endef

define WSLU_INSTALL_TARGET_CMDS
	$(TARGET_MAKE_ENV) $(MAKE) -C $(@D) DESTDIR=$(TARGET_DIR) install
endef

$(eval $(generic-package))
