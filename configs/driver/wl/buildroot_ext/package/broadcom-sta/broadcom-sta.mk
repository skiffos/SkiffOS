################################################################################
#
# broadcom-sta
#
################################################################################

BROADCOM_STA_VERSION = a9362f4e4416d8e842b976fd243445711363ec24
BROADCOM_STA_SITE = $(call github,antoineco,broadcom-wl,$(BROADCOM_STA_VERSION))
LICENSE = Proprietary

BROADCOM_STA_MODULE_MAKE_OPTS = \
	CONFIG_WL=m \
	KVER=$(LINUX_VERSION_PROBED)

$(eval $(kernel-module))
$(eval $(generic-package))
