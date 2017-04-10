warn:
	@echo "$(tput smso)Please run make from the root dir, not build.$(tput sgr0)"
	@echo "Please run make from the root dir, not build."
	exit 1

cmd/%:
	@$(SKIFF_SCRIPTS_DIR)/execute_command.sh $@

help:
	@cd $(SKIFF_SCRIPTS_DIR) && $(SKIFF_SCRIPTS_DIR)/print_help.sh

ensure-submodule:
	@$(SKIFF_SCRIPTS_DIR)/ensure_submodule.sh

ensure-workspace: ensure-submodule
	@$(SKIFF_SCRIPTS_DIR)/setup_workspace.sh

ensure-sane: ensure-submodule ensure-workspace

verify-skiff-config:
	@$(SKIFF_SCRIPTS_DIR)/verify_selected_config.sh

maybe-build-configs:
	@$(SKIFF_SCRIPTS_DIR)/build_configs.sh

configure: ensure-sane
	@SKIFF_FORCE_RECONFIG=true $(SKIFF_SCRIPTS_DIR)/build_configs.sh

cleanup-workspace:
	@$(SKIFF_SCRIPTS_DIR)/cleanup_workspace.sh

clean: ensure-submodule cleanup-workspace

# Build
compile: ensure-sane verify-skiff-config maybe-build-configs
	@echo "$$(tput smso)Kicking off Buildroot build...$$(tput sgr0)"
	cd $$BUILDROOT_DIR && make
	@echo "$$(tput smso)Compilation complete!$$(tput sgr0)"
