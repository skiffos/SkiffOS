PRIMARY_ENV= \
	export ROOT_DIR=$$(pwd) && \
		export SKIFF_FINAL_CONFIG_DIR=$${ROOT_DIR}/.config && \
		export SKIFF_CONFIGS_DIR=$${ROOT_DIR}/configs && \
		export SKIFF_RESOURCES_DIR=$${ROOT_DIR}/resources && \
		export SKIFF_BASE_CONFIGS_DIR=$${ROOT_DIR}/configs-base && \
		export SKIFF_SCRIPTS_DIR=$${ROOT_DIR}/scripts && \
		export BUILDROOT_DIR=$${ROOT_DIR}/buildroot && \
	  cd configs && \
		. ../scripts/maybe_recover_skiff_config.sh && \
		. ../scripts/enumerate_configs.sh > /dev/null &&

%:
	@$(PRIMARY_ENV) \
		cd ../build && \
		make $@

help:
	@$(PRIMARY_ENV) \
		cd ../scripts && \
		./print_help.sh

.PHONY: help build
