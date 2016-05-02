warn:
	@echo "$(tput smso)Please run make from the root dir, not build.$(tput sgr0)"
	@echo "Please run make from the root dir, not build."
	exit 1

ensure-submodule:
	@$(SKIFF_SCRIPTS_DIR)/ensure_submodule.sh

ensure-sane: ensure-submodule

verify-skiff-config:
	@$(SKIFF_SCRIPTS_DIR)/verify_selected_config.sh

maybe-build-configs:
	@$(SKIFF_SCRIPTS_DIR)/build_configs.sh

configure: ensure-sane
	@SKIFF_FORCE_RECONFIG=true $(SKIFF_SCRIPTS_DIR)/build_configs.sh

# Build
compile: ensure-sane verify-skiff-config maybe-build-configs
	@echo "$$(tput smso)Kicking off Buildroot build...$$(tput sgr0)"
	cd $$BUILDROOT_DIR && make
	@echo "$$(tput smso)Compilation complete!$$(tput sgr0)"
