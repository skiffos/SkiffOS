#!/usr/bin/env bash
# Start a shell in the Buildroot directory
set -eo pipefail

# Source any environment binding configuration if present
if [[ -d ${SKIFF_FINAL_CONFIG_DIR} ]]; then
	source "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh"
fi

# Change to Buildroot directory and start a shell
cd "${SKIFF_BUILDROOT_DIR}"
bash
