################################################################################
#
# broadcom-sta
#
################################################################################

BROADCOM_STA_VERSION = c393e8aa87d286708bcb868549bcb2013391c5f7
BROADCOM_STA_SITE = $(call github,antoineco,broadcom-wl,$(BROADCOM_STA_VERSION))
LICENSE = Proprietary

BROADCOM_STA_MODULE_MAKE_OPTS = \
	CONFIG_WL=m \
	KVER=$(LINUX_VERSION_PROBED)

$(eval $(kernel-module))
$(eval $(generic-package))
