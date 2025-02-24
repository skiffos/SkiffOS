#!/usr/bin/env bash
# SkiffOS configuration recovery script
# Attempts to recover SKIFF_CONFIG and SKIFF_EXTRA_CONFIGS_PATH from saved configuration
set -eo pipefail

# Define path to saved configuration files
SKIFF_CONFIG_FILE="${SKIFF_FINAL_CONFIG_DIR}/skiff_config"
SKIFF_EXTRA_CONFIGS_PATH_FILE="${SKIFF_FINAL_CONFIG_DIR}/skiff_extra_configs_path"

# Check if configuration directory exists
if [[ ! -d ${SKIFF_FINAL_CONFIG_DIR} ]]; then
	# No configuration directory found, nothing to recover
	return 0
fi

# Recover SKIFF_CONFIG if not already set
if [[ -f ${SKIFF_CONFIG_FILE} ]] && [[ -z ${SKIFF_CONFIG} ]]; then
	# Read saved configuration
	SAVED_CONFIG=$(cat "${SKIFF_CONFIG_FILE}")

	if [[ -n ${SAVED_CONFIG} ]]; then
		# Set warning flag and restore configuration
		export SKIFF_WARN_ABOUT_RECOVERED_CONFIG=true
		export SKIFF_CONFIG="${SAVED_CONFIG}"
	fi
fi

# Recover SKIFF_EXTRA_CONFIGS_PATH if not already set
if [[ -f ${SKIFF_EXTRA_CONFIGS_PATH_FILE} ]] && [[ -z ${SKIFF_EXTRA_CONFIGS_PATH} ]]; then
	# Read saved extra configs path
	SAVED_EXTRA_CONFIGS_PATH=$(cat "${SKIFF_EXTRA_CONFIGS_PATH_FILE}")

	if [[ -n ${SAVED_EXTRA_CONFIGS_PATH} ]]; then
		# Restore extra configs path
		export SKIFF_EXTRA_CONFIGS_PATH="${SAVED_EXTRA_CONFIGS_PATH}"
	fi
fi
