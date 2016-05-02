
warn:
	@echo "$(tput smso)Please run make from the root dir, not build.$(tput sgr0)"
	@echo "Please run make from the root dir, not build."
	exit 1

verify-skiff-config:
	@$(SKIFF_SCRIPTS_DIR)/verify_selected_config.sh

maybe-build-configs:
	@$(SKIFF_SCRIPTS_DIR)/build_configs.sh

configure:
	@SKIFF_FORCE_RECONFIG=true $(SKIFF_SCRIPTS_DIR)/build_configs.sh

# Build
compile: verify-skiff-config maybe-build-configs
	@echo "$(tput smso)Kicking off Buildroot build...$(tput sgr0)"
