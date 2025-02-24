#!/usr/bin/env bash
# SkiffOS configuration verification script
# Verifies that a valid configuration is selected
set -eo pipefail

# Function to print error messages to stderr
function errecho() {
	echo "$1" >&2
}

# Ensure configs are enumerated
# This enables us to verify if the selected config exists
if [[ -z ${SKIFF_HAS_ENUMERATED_CONFIGS} ]]; then
	# Assume we are in the configs directory
	if [[ ! -f "../scripts/enumerate_configs.sh" ]]; then
		errecho "Error: Cannot locate enumerate_configs.sh script."
		errecho "Please run this script from the configs directory."
		exit 1
	fi

	# Source the enumeration script
	. ../scripts/enumerate_configs.sh
fi

# Verify SKIFF_CONFIG is set
if [[ -z ${SKIFF_CONFIG} ]]; then
	errecho "Error: SKIFF_CONFIG environment variable is not set."
	errecho "Please set SKIFF_CONFIG to specify the configuration(s) to use."
	errecho "Example: export SKIFF_CONFIG=odroid/xu4,apps/docker"
	exit 1
fi

echo "Configuration verified: ${SKIFF_CONFIG}"
