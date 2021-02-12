################################################################################
#
# skiff-core
#
################################################################################

SKIFF_CORE_VERSION = v1.5.4
SKIFF_CORE_SITE = $(call github,paralin,skiff-core,$(SKIFF_CORE_VERSION))
SKIFF_CORE_LICENSE = MIT
SKIFF_CORE_LICENSE_FILES = LICENSE

SKIFF_CORE_BUILD_TARGETS = cmd/skiff-core

SKIFF_CORE_TAGS = cgo static_build
SKIFF_CORE_LDFLAGS = \
	-X main.gitCommit="$(SKIFF_CORE_VERSION)"

SKIFF_CORE_INSTALL_BINS = $(notdir $(SKIFF_CORE_BUILD_TARGETS))

$(eval $(golang-package))

