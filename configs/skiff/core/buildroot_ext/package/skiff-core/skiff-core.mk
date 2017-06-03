################################################################################
#
# skiff-core
#
################################################################################

SKIFF_CORE_VERSION = v0.2.6
SKIFF_CORE_SITE = $(call github,paralin,skiff-core,$(SKIFF_CORE_VERSION))
SKIFF_CORE_LICENSE = GPLv2+
SKIFF_CORE_LICENSE_FILES = LICENSE

SKIFF_CORE_DEPENDENCIES = host-go
SKIFF_CORE_GOPATH = "$(@D)/gopath"
SKIFF_CORE_MAKE_ENV = $(HOST_GO_TARGET_ENV) \
	CGO_ENABLED=1 \
	GOBIN="$(@D)/bin" \
	GOPATH="$(SKIFF_CORE_GOPATH)" \
	PATH=$(BR_PATH)
SKIFF_CORE_PKG = github.com/paralin/skiff-core

SKIFF_CORE_GLDFLAGS = \
	-X main.gitCommit=$(SKIFF_CORE_VERSION)

ifeq ($(BR2_STATIC_LIBS),y)
SKIFF_CORE_GLDFLAGS += -extldflags '-static'
endif

SKIFF_CORE_GOTAGS = cgo static_build

define SKIFF_CORE_CONFIGURE_CMDS
	mkdir -p $(SKIFF_CORE_GOPATH)/src/$$(dirname $(SKIFF_CORE_PKG))
	ln -s $(@D) $(SKIFF_CORE_GOPATH)/src/$(SKIFF_CORE_PKG)
endef

define SKIFF_CORE_BUILD_CMDS
	cd $(SKIFF_CORE_GOPATH)/src/$(SKIFF_CORE_PKG) && \
		$(SKIFF_CORE_MAKE_ENV) $(HOST_DIR)/usr/bin/go \
		build -v -o $(SKIFF_CORE_GOPATH)/bin/skiff-core \
		-tags "$(SKIFF_CORE_GOTAGS)" -ldflags "$(SKIFF_CORE_GLDFLAGS)" \
		$(SKIFF_CORE_PKG)/cmd/skiff-core
endef

define SKIFF_CORE_INSTALL_TARGET_CMDS
	$(INSTALL) -D -m 0755 $(SKIFF_CORE_GOPATH)/bin/skiff-core $(TARGET_DIR)/usr/bin/skiff-core
endef

$(eval $(generic-package))
