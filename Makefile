%:
	@export ROOT_DIR=$$(pwd) && \
		export SKIFF_CONFIGS_DIR=$${ROOT_DIR}/configs && \
		export SKIFF_SCRIPTS_DIR=$${ROOT_DIR}/scripts && \
		export BUILDROOT_DIR=$${ROOT_DIR}/buildroot && \
	  cd configs && \
		. ../scripts/enumerate_configs.sh && \
		cd ../build && \
		make $@

help:
	@cd scripts && ./print_help.sh
