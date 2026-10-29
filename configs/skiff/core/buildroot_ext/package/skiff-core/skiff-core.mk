################################################################################
#
# skiff-core
#
################################################################################

SKIFF_CORE_VERSION = 26bdd4892e70838216b570d5a510e67897fb422f
SKIFF_CORE_SITE = $(call github,skiffos,skiff-core,$(SKIFF_CORE_VERSION))
SKIFF_CORE_LICENSE = MIT
SKIFF_CORE_LICENSE_FILES = LICENSE

SKIFF_CORE_BUILD_TARGETS = cmd/skiff-core

SKIFF_CORE_TAGS = cgo static_build
SKIFF_CORE_LDFLAGS = \
	-X main.gitCommit="$(SKIFF_CORE_VERSION)"

$(eval $(golang-package))
