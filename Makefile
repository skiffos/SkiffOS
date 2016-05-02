%:
	@export ROOT_DIR=$$(pwd) && \
		export SKIFF_FINAL_CONFIG_DIR=$${ROOT_DIR}/.config && \
		export SKIFF_CONFIGS_DIR=$${ROOT_DIR}/configs && \
		export SKIFF_RESOURCES_DIR=$${ROOT_DIR}/resources && \
		export SKIFF_BASE_CONFIGS_DIR=$${ROOT_DIR}/configs-base && \
		export SKIFF_SCRIPTS_DIR=$${ROOT_DIR}/scripts && \
		export BUILDROOT_DIR=$${ROOT_DIR}/buildroot && \
	  cd configs && \
		. ../scripts/enumerate_configs.sh && \
		cd ../build && \
		make $@

help:
	@cd scripts && ./print_help.sh

.PHONY: help build
