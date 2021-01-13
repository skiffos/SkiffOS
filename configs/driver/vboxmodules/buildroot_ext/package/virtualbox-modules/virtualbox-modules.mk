################################################################################
#
# virtualbox-modules
#
################################################################################

VIRTUALBOX_MODULES_VERSION = 6.1.16
VIRTUALBOX_MODULES_SITE = https://dev.gentoo.org/~polynomial-c/virtualbox
VIRTUALBOX_MODULES_SOURCE = vbox-kernel-module-src-$(VIRTUALBOX_MODULES_VERSION).tar.xz
VIRTUALBOX_MODULES_LICENSE = GPL-2

$(eval $(kernel-module))
$(eval $(generic-package))
