#!/usr/bin/env bash
# Configuration enumeration and dependency resolution for SkiffOS
# This script discovers available configuration packages and their metadata
set -eo pipefail

# Source utility functions
. ../scripts/utils.sh

# Utility functions

# Silence output from pushd/popd
function pushd() {
	command pushd "$@" 2>&1 >/dev/null
}

function popd() {
	command popd "$@" 2>&1 >/dev/null
}

# Join array elements with a delimiter
# Usage: joinStr "," "${array[@]}"
function joinStr() {
	local IFS="$1"
	shift
	echo "$*"
}

# Check if an element exists in an array
# Usage: containsElement "element" "${array[@]}"
function containsElement() {
	local element="$1"
	local -a array=("${@:2}")
	for e in "${array[@]}"; do
		[[ $e == "$element" ]] && return 0
	done
	return 1
}

# Convert a config path to an environment variable name
# Usage: path_to_var "PREFIX_" "category/name"
function path_to_var() {
	local prefix="$1"
	local path="$2"
	local normalized_path=$(echo "$path" | tr '[:lower:]' '[:upper:]' | sed "s#/#_#g")
	echo "${prefix}${normalized_path}"
}

# Discover and register configuration packages
function discover_config_packages() {
	# Set up config paths, including extra paths if defined
	local SKIFF_CONFIGS_PATH="$(pwd)"
	if [[ -n $SKIFF_EXTRA_CONFIGS_PATH ]]; then
		SKIFF_CONFIGS_PATH="${SKIFF_EXTRA_CONFIGS_PATH}:${SKIFF_CONFIGS_PATH}"
	fi

	# Process each config path
	local config_path_remaining="$SKIFF_CONFIGS_PATH"
	while [[ -n $config_path_remaining ]]; do
		# Extract the next path from the colon-separated list
		local current_path="${config_path_remaining%%:*}"

		# Try to access the path
		if ! pushd "$current_path"; then
			{
				echo "! SKIFF_EXTRA_CONFIGS_PATH contains an inaccessible path:"
				echo "$current_path"
				echo "This path will be ignored. Some packages may be unavailable."
			} >&2
			local packages=""
		else
			# Find all configuration packages (subdirectories two levels deep)
			local packages=$(find . -mindepth 2 -maxdepth 2 -type d | sed -n 's#[^/]*/##p' | tr '\n' ':')
			popd
		fi

		# Process each package in this path
		while [[ -n $packages ]]; do
			local package="${packages%%:*}"

			# Skip packages with invalid characters
			if [[ $package =~ [^a-zA-Z0-9/\\_] ]]; then
				echo "! [$package] (ignored, invalid characters)"
			else
				# Convert package path to environment variable names
				local env_var_name=$(path_to_var "${SKIFF_PACKAGE_ENV_PREFIX}" "$package")
				local name_var_name=$(path_to_var "${SKIFF_PACKAGE_NAME_ENV_PREFIX}" "$package")

				# Create the full path to the package
				local package_path="${current_path}/${package}"
				package_path=$(echo "$package_path" | sed -e "s#//#/#g")

				# Register the package if not already defined
				if [[ -z ${!env_var_name} ]]; then
					echo " > [$package] [$package_path]"
					export ${env_var_name}="$package_path"
					export ${name_var_name}="$package"
				fi
			fi

			# Move to next package in the list
			if [[ $packages == "$package" ]]; then
				packages=""
			else
				packages="${packages#*:}"
			fi
		done

		# Move to next path in the list
		if [[ $config_path_remaining == "$current_path" ]]; then
			config_path_remaining=""
		else
			config_path_remaining="${config_path_remaining#*:}"
		fi
	done
}

# Process the configuration chain specified in SKIFF_CONFIG
function process_config_chain() {
	if [[ -z $SKIFF_CONFIG ]]; then
		return
	fi

	local REQUIRES_REEVAL=true
	while $REQUIRES_REEVAL; do
		REQUIRES_REEVAL=false
		echo "Selected config chain (from SKIFF_CONFIG):"

		# Normalize SKIFF_CONFIG (trim whitespace, convert commas to spaces)
		export SKIFF_CONFIG=$(
			echo "$SKIFF_CONFIG" |
				sed 's/^ *//;s/ *$//' |
				sed 's/,/ /g' |
				tr -s " "
		)

		# Convert to array and initialize tracking variables
		SKIFF_CONFIGS=($SKIFF_CONFIG)
		SKIFF_CONFIG_FULL=()
		SKIFF_CONFIG_PATH_VAR=()
		SKIFF_CONFIG_PATH=()
		SKIFF_CONFIGS_FINAL=()

		# Process each configuration
		for conf in "${SKIFF_CONFIGS[@]}"; do
			# Validate config format (category/name)
			if [[ -z "$(echo "$conf" | grep '^[[:alnum:]]\{1,100\}/.*$')" ]]; then
				echo " ! [$conf] Invalid config, should be category/name. Ignored." >&2
				continue
			fi

			# Skip if already processed
			if containsElement "$conf" "${SKIFF_CONFIGS_FINAL[@]}"; then
				continue
			fi

			# Get path to the configuration
			local conf_full=$(echo "$conf" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')
			local path_var="${SKIFF_PACKAGE_ENV_PREFIX}${conf_full}"
			local conf_path="${!path_var}"

			# Validate the path exists
			if [[ -z $conf_path ]]; then
				echo " ! [$conf] Unknown path! $path_var not set." >&2
				exit 1
			fi

			if [[ ! -d $conf_path ]]; then
				echo " ! [$conf] Path $conf_path does not exist. Ignored." >&2
				continue
			fi

			# Process dependencies if present
			if [[ -f "$conf_path/metadata/dependencies" ]]; then
				local dependencies=$(cat "$conf_path/metadata/dependencies")

				# Validate dependencies format
				if [[ $dependencies =~ [^\,\ a-zA-Z0-9_/\\] ]]; then
					echo " ! [$conf] Invalid dependencies: $dependencies" >&2
					continue
				fi

				local invalid_dependency=false
				# Split dependencies string into array
				local dependency_array=($(echo "$dependencies" | sed 's/^ *//;s/ *$//' | sed 's/,/ /g' | tr -s " "))

				for dep in "${dependency_array[@]}"; do
					# Validate dependency format
					if [[ -z "$(echo "$dep" | grep '^[[:alnum:]]\{1,100\}/.*$')" ]]; then
						echo " ! [$conf] Invalid dependency: $dep" >&2
						invalid_dependency=true
						continue
					fi

					# Add dependency to config list if not already present
					if ! containsElement "$dep" "${SKIFF_CONFIGS[@]}"; then
						SKIFF_CONFIGS_FINAL+=("$dep")
						REQUIRES_REEVAL=true
					fi
				done

				if $invalid_dependency; then
					continue
				fi
			fi

			# Check for build target override
			if [[ -f "$conf_path/metadata/buildtarget" ]] && [[ -z $SKIFF_BUILD_TARGET_OVERRIDE ]]; then
				SKIFF_BUILD_TARGET_OVERRIDE="$(cat "$conf_path/metadata/buildtarget")"
			fi

			# Process commands if present
			echo "$conf_path"
			if [[ -f "$conf_path/metadata/commands" ]] && [[ -d "$conf_path/extensions" ]]; then
				local cmd_list=()
				local cmd_paths=()

				while read -r line; do
					# Parse command and description
					local cmdn=($(echo "$line" | sed 's/^ *//;s/ *$//' | sed 's/,/ /g' | tr -s " "))
					if ((${#cmdn[@]} < 2)); then
						continue
					fi

					local cmdname="${cmdn[0]}"
					local descrip="${cmdn[@]:1}"
					local cmdname_full=$(echo "$cmdname" | tr '[:lower:]' '[:upper:]' | sed -e 's#-#_#g')

					cmd_list+=("$cmdname")
					cmd_paths+=("$conf_path/extensions/")

					# Export command description
					eval "export SKIFF_${conf_full}_COMMAND_${cmdname_full}_DESCRIP=\${descrip}"

					# Join arrays with spaces
					printf -v "SKIFF_${conf_full}_COMMAND_LIST" '%s' "${cmd_list[*]}"
					printf -v "SKIFF_${conf_full}_COMMAND_PATHS" '%s' "${cmd_paths[*]}"
				done < <(cat "$conf_path/metadata/commands")

				# Export command lists
				eval "export SKIFF_${conf_full}_COMMAND_LIST=\"\${SKIFF_${conf_full}_COMMAND_LIST}\""
				eval "export SKIFF_${conf_full}_COMMAND_PATHS=\"\${SKIFF_${conf_full}_COMMAND_PATHS}\""
			fi

			# Add config to final list
			SKIFF_CONFIG_FULL+=("$conf_full")
			SKIFF_CONFIG_PATH_VAR+=("$path_var")
			SKIFF_CONFIG_PATH+=("$conf_path")
			SKIFF_CONFIGS_FINAL+=("$conf")
			echo " > [$conf] [$conf_path]"
		done

		# Export final configurations
		unset SKIFF_CONFIGS
		export SKIFF_CONFIGS="${SKIFF_CONFIGS_FINAL[@]}"

		local tmp="${SKIFF_CONFIG_FULL[@]}"
		unset SKIFF_CONFIG_FULL
		export SKIFF_CONFIG_FULL="$tmp"

		tmp="${SKIFF_CONFIG_PATH_VAR[@]}"
		unset SKIFF_CONFIG_PATH_VAR
		export SKIFF_CONFIG_PATH_VAR="$tmp"

		tmp="${SKIFF_CONFIG_PATH[@]}"
		unset SKIFF_CONFIG_PATH
		export SKIFF_CONFIG_PATH="$tmp"

		# Update SKIFF_CONFIG with final comma-separated list
		export SKIFF_CONFIG=$(joinStr , "${SKIFF_CONFIGS_FINAL[@]}")

		if $REQUIRES_REEVAL; then
			echo "Re-evaluating configs due to dep change:"
		fi
	done
}

# Main execution
discover_config_packages
process_config_chain

# Mark enumeration as complete
export SKIFF_HAS_ENUMERATED_CONFIGS="yes"
export SKIFF_BUILD_TARGET_OVERRIDE
