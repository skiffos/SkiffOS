#!/usr/bin/env bash
# SkiffOS buildroot command executor
# Executes a buildroot make command with the proper environment
set -eo pipefail

# Verify configuration directory exists
if [[ ! -d ${SKIFF_FINAL_CONFIG_DIR} ]]; then
	echo "Error: Configuration directory not found."
	echo "Please run 'make configure' first to set up the build environment."
	exit 1
fi

# Source the environment binding script
if [[ ! -f "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh" ]]; then
	echo "Error: Environment binding script not found."
	echo "Please run 'make configure' to generate it."
	exit 1
fi
source "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh"

# Verify buildroot directory exists
if [[ ! -d ${BUILDROOT_DIR} ]]; then
	echo "Error: Buildroot directory not found at ${BUILDROOT_DIR}."
	exit 1
fi

# Extract the command part after 'br/'
BR_COMMAND="${@#*br/}"

# Execute the buildroot command
echo "Executing in buildroot: make ${BR_COMMAND}"
cd "${BUILDROOT_DIR}" && make ${BR_COMMAND}
