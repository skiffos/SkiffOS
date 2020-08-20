warn:
	@echo "$(tput smso)Please run make from the root dir, not build.$(tput sgr0)"
	@echo "Please run make from the root dir, not build."
	exit 1

env:
	env

cmd/%:
	@$(SKIFF_SCRIPTS_DIR)/execute_command.sh $@

br/%: ensure-sane verify-skiff-config maybe-build-configs
	@$(SKIFF_SCRIPTS_DIR)/execute_buildroot_command.sh $@

help:
	@cd $(SKIFF_SCRIPTS_DIR) && $(SKIFF_SCRIPTS_DIR)/print_help.sh

ensure-submodule:
	@git config core.hooksPath .githooks || echo "Failed to register Git Hooks."
	@$(SKIFF_SCRIPTS_DIR)/ensure_submodule.sh

ensure-workspace: ensure-submodule
	@$(SKIFF_SCRIPTS_DIR)/setup_workspace.sh

ensure-sane: ensure-submodule ensure-workspace

shell: ensure-sane ensure-workspace
	@$(SKIFF_SCRIPTS_DIR)/bind_shell.sh

verify-skiff-config:
	@$(SKIFF_SCRIPTS_DIR)/verify_selected_config.sh

maybe-build-configs:
	@$(SKIFF_SCRIPTS_DIR)/build_configs.sh

check-package-buildroot-ext: ensure-submodule
	@$(SKIFF_SCRIPTS_DIR)/check_package_buildroot_ext.sh

configure: ensure-sane
	@SKIFF_FORCE_RECONFIG=true $(SKIFF_SCRIPTS_DIR)/build_configs.sh

cleanup-workspace:
	@$(SKIFF_SCRIPTS_DIR)/cleanup_workspace.sh

clean: ensure-submodule cleanup-workspace

graph-build: ensure-sane verify-skiff-config maybe-build-configs
	@echo "$$(tput smso)Building build-time graphs...$$(tput sgr0)"
	@$(SKIFF_SCRIPTS_DIR)/graph_build_time.sh

graph-size: ensure-sane verify-skiff-config maybe-build-configs
	@echo "$$(tput smso)Building target-size graphs...$$(tput sgr0)"
	@$(SKIFF_SCRIPTS_DIR)/graph_size.sh

graph: graph-build graph-size

legal-info: ensure-sane verify-skiff-config maybe-build-configs
	@echo "$$(tput smso)Preparing legal info...$$(tput sgr0)"
	cd $$BUILDROOT_DIR && make legal-info

# Build
compile: ensure-sane verify-skiff-config maybe-build-configs
	@echo "$$(tput smso)Kicking off Buildroot build...$$(tput sgr0)"
	cd $$BUILDROOT_DIR && make $(SKIFF_BUILD_TARGET_OVERRIDE)
	@echo "$$(tput smso)Compilation complete!$$(tput sgr0)"

# Check
check: ensure-sane verify-skiff-config maybe-build-configs check-package-buildroot-ext
	@echo "$$(tput smso)Downloading and hashing all sources...$$(tput sgr0)"
	cd $$BUILDROOT_DIR && make source
	@echo "$$(tput smso)Building legal information...$$(tput sgr0)"
	cd $$BUILDROOT_DIR && make legal-info
	@echo "$$(tput smso)Checks complete.$$(tput sgr0)"

