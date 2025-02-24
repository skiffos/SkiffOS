#!/usr/bin/env bash
# Workspace validation and path setup for SkiffOS
# Sets up the workspace environment variables

# Return to root directory
cd "${ROOT_DIR}"

# Clean and normalize workspace name, defaulting to 'default'
export SKIFF_WORKSPACE=$(echo "${SKIFF_WORKSPACE}" | tr -cd '[[:alnum:]]._-' | tr '[:upper:]' '[:lower:]')
if [[ -z ${SKIFF_WORKSPACE} ]]; then
	export SKIFF_WORKSPACE="default"
fi

# Set up workspace-specific paths
export SKIFF_FINAL_CONFIG_DIR="${SKIFF_WORKSPACES_DIR}/.config_${SKIFF_WORKSPACE}/"
export SKIFF_WS_OVERRIDES_DIR="${SKIFF_OVERRIDES_DIR}/workspaces/${SKIFF_WORKSPACE}/"

# Set up ccache directory if not already configured
if [[ -z ${BR2_CCACHE_DIR} ]]; then
	export BR2_CCACHE_DIR="${SKIFF_WORKSPACES_DIR}/.ccache/${SKIFF_WORKSPACE}"
	if [[ ! -d ${BR2_CCACHE_DIR} ]]; then
		mkdir -p "${BR2_CCACHE_DIR}"
	fi
fi

# Return to previous directory
cd - >/dev/null
