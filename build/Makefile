
warn:
	@echo "Please run make from the root dir, not build."
	exit 1

verify-skiff-config:
	@echo $(SKIFF_CONFIGS_DIR)
	@$(SKIFF_SCRIPTS_DIR)/verify_selected_config.sh

build-buildroot-config:
	@$(SKIFF_SCRIPTS_DIR)/build_buildroot_config.sh

# Build
compile:
	@echo -e "Building..."
