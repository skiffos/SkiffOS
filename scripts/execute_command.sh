#!/usr/bin/env bash
# SkiffOS configuration package command executor
# Executes a command defined in a configuration package's extensions directory
set -eo pipefail

# Check if array contains a specific element
# Usage: containsElement "needle" "${haystack[@]}"
function containsElement() {
	local needle="$1"
	local -a haystack=("${@:2}")
	for element in "${haystack[@]}"; do
		[[ $element == "$needle" ]] && return 0
	done
	return 1
}

# Convert a configuration path to an environment variable name
# Usage: path_to_var "category/name"
function path_to_var() {
	local config_path="$1"
	local normalized_path=$(echo "$config_path" | tr '[:lower:]' '[:upper:]' | sed "s#/#_#")
	echo "${SKIFF_PACKAGE_ENV_PREFIX}${normalized_path}"
}

# Parse the command into parts
# The format is cmd/category/name/command
parts=($(echo "$@" | sed -e "s#/# #g"))
parts=("${parts[@]:1}") # Remove the 'cmd' part

# Validate command structure
if [[ ${#parts[@]} != "3" ]]; then
	echo "$(tput smso)Invalid command format: $@$(tput sgr0)"
	echo "Usage: make cmd/category/name/command"
	exit 1
fi

# Extract configuration and command
config_path="${parts[0]}/${parts[1]}"
command_name="${parts[2]}"

# Convert config path to environment variable name
config_var=$(path_to_var "$config_path")

# Check if configuration exists
if [[ -z ${!config_var} ]]; then
	echo "$(tput smso)Configuration package not found: ${config_path}$(tput sgr0)"
	echo "Variable name: ${config_var}"
	exit 1
fi

# Get the full path to the extensions directory
extensions_path="${!config_var}/extensions"

# Verify extensions directory exists
if [[ ! -d ${extensions_path} ]]; then
	echo "$(tput smso)Extensions directory not found: ${extensions_path}$(tput sgr0)"
	exit 1
fi

# Source environment binding script if it exists
if [[ -f "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh" ]]; then
	source "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh"
else
	echo "Warning: Environment binding script not found. Some environment variables may be missing."
fi

# Set up environment for the command
export SKIFF_CURRENT_CONF_DIR="${!config_var}"
export SKIFF_CURRENT_CONF_NAME="${config_path}"
export SKIFF_CURRENT_CONF_NAME_FULL="${config_var}"

# Execute the command
echo "Executing command '${command_name}' from '${config_path}' extensions..."
cd "${extensions_path}" && make "${command_name}"
