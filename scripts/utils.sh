#!/usr/bin/env bash
# SkiffOS utility functions and environment variable definitions
# This file is sourced by other scripts to provide shared functionality

# Configuration package environment variable prefixes
export SKIFF_PACKAGE_ENV_PREFIX="SKIFF_CONFIG_PATH_"
export SKIFF_PACKAGE_NAME_ENV_PREFIX="SKIFF_CONFIG_NAME_"
export SKIFF_FILTER_ENVS="grep ^${SKIFF_PACKAGE_ENV_PREFIX}[[:alnum:]]*_.*="

# Config metadata paths and filenames
export SKIFF_CONFIG_METADATA_SUBDIR="metadata"
export SKIFF_CONFIG_METADATA_DESCRIPTION="description"
export SKIFF_CONFIG_METADATA_NOLIST="unlisted"
export SKIFF_CONFIG_METADATA_UNIQUEGROUP="uniquegroup"

# Force a variable to be an array if it isn't already
# Usage: force_arr VARIABLE_NAME
function force_arr() {
	if [[ -n ${!1} ]]; then
		if ! [[ "$(declare -p "$1" 2>/dev/null)" =~ "declare -a" ]]; then
			eval "export $1=( \${$1} )"
		fi
	fi
}

# Ensure these variables are treated as arrays
force_arr SKIFF_CONFIG_PATH
force_arr SKIFF_CONFIGS
