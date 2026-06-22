################################################################################
#
# skiff-core
#
################################################################################

SKIFF_CORE_VERSION = 966c6bcedf3a8526ce0bc1d5f92d1f7a6b367790
SKIFF_CORE_SITE = $(call github,skiffos,skiff-core,$(SKIFF_CORE_VERSION))
SKIFF_CORE_LICENSE = MIT
SKIFF_CORE_LICENSE_FILES = LICENSE

SKIFF_CORE_BUILD_TARGETS = cmd/skiff-core

SKIFF_CORE_TAGS = cgo static_build
SKIFF_CORE_LDFLAGS = \
	-X main.gitCommit="$(SKIFF_CORE_VERSION)"

$(eval $(golang-package))
