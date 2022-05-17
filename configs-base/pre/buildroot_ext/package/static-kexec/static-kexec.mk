################################################################################
#
# static-kexec
#
################################################################################

STATIC_KEXEC_VERSION = 2.0.23
STATIC_KEXEC_SOURCE = kexec-tools-$(STATIC_KEXEC_VERSION).tar.xz
STATIC_KEXEC_SITE = $(BR2_KERNEL_MIRROR)/linux/utils/kernel/kexec

STATIC_KEXEC_LICENSE = GPL-2.0
STATIC_KEXEC_LICENSE_FILES = COPYING

# STATIC_KEXEC_SELINUX_MODULES = kdump
STATIC_KEXEC_INSTALL_TARGET = NO
STATIC_KEXEC_INSTALL_STAGING = NO
STATIC_KEXEC_INSTALL_IMAGES = YES

# Makefile expects $STRIP -o to work, so needed for !BR2_STRIP_strip
STATIC_KEXEC_MAKE_OPTS = STRIP="$(TARGET_CROSS)strip"

STATIC_KEXEC_CONF_OPTS += LDFLAGS=-static
STATIC_KEXEC_CONF_OPTS += --without-zlib
STATIC_KEXEC_CONF_OPTS += --without-lzma

define STATIC_KEXEC_INSTALL_IMAGES_CMDS
	mkdir -p $(BINARIES_DIR)/skiff-init
	$(INSTALL) -m 755 -D $(STATIC_KEXEC_SRCDIR)/build/sbin/kexec \
		 $(BINARIES_DIR)/skiff-init/kexec
endef

$(eval $(autotools-package))
