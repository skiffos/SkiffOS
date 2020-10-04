################################################################################
#
# rtl8723cs
#
################################################################################

RTL8723CS_VERSION = 381dd529fbe26fd758ef9c72be8fe3f2cb6c412c
RTL8723CS_SITE = $(call github,paralin,rtl8723cs,$(RTL8723CS_VERSION))
RTL8723CS_LICENSE = GPL-2.0
RTL8723CS_LICENSE_FILES = LICENSE

RTL8723CS_MODULE_MAKE_OPTS = \
	CONFIG_RTL8723CS=m \
	KVER=$(LINUX_VERSION_PROBED) \
	USER_EXTRA_CFLAGS="-DCONFIG_$(call qstrip,$(BR2_ENDIAN))_ENDIAN \
		-Wno-error"

$(eval $(kernel-module))
$(eval $(generic-package))
