#!/usr/bin/env bash
# SkiffOS help display script
# Displays available configurations and commands
set -eo pipefail

# Source utility functions
source ../scripts/utils.sh

# Display logo and version information
echo ""
cat ../resources/text/logo.ascii
echo ""
printf "\033[0;32mWelcome to SkiffOS ${SKIFF_VERSION}!\033[0m\n"
echo ""

# Display workspace and config information
printf "\033[0;34m ✓ SKIFF_WORKSPACE is: ${SKIFF_WORKSPACE}\033[0m\n"

# Show message if config was recovered from previous session
if [[ -n ${SKIFF_WARN_ABOUT_RECOVERED_CONFIG} ]]; then
	printf "\033[0;34m ✓ Previous config recovered\033[0m\n"
fi

# Verify and display selected configuration
if ERR=$(../scripts/verify_selected_config.sh 2>&1); then
	printf "\033[0;34m ✓ Selected config chain:\033[0m\n"

	# Display each configuration in the chain with description
	for ((i = 0; i < ${#SKIFF_CONFIGS[@]}; i++)); do
		conf="${SKIFF_CONFIGS[i]}"
		conf_path="${SKIFF_CONFIG_PATH[i]}"
		description_path="${conf_path}/${SKIFF_CONFIG_METADATA_SUBDIR}/${SKIFF_CONFIG_METADATA_DESCRIPTION}"

		description=""
		if [[ -f ${description_path} ]]; then
			description=$(cat "${description_path}")
		fi

		# Format and display the configuration
		printf "     "
		printf '\e[107m\033[0;45m%s\033[0m\e[49m\t %s\n' "${conf}" "${description}" | expand -t 22
	done
else
	# Display error if configuration verification failed
	printf "\033[1;49;31m✖ ${ERR}\033[0m\n"
fi

# Display available configurations
echo
echo -e "\e[0;31m\033[1mConfigurations\e[0m"
echo -e "Set SKIFF_CONFIG to one or more of the following (comma separated):"
cd ../configs/ && ../scripts/print_packages_help.sh
cd - >/dev/null
echo

# Display core build commands
echo -e "\e[0;31m\033[1mBuild Commands\e[0m"
echo -e "\033[0;34mconfigure\033[0m:  Force a re-configuration of the system."
echo -e "\033[0;34mcompile\033[0m:    Configures and compiles the system."
echo -e "\033[0;34mclean\033[0m:      Cleans the current workspace."
echo

# Display utility commands
echo -e "\e[0;31m\033[1mUtility Commands\e[0m"
echo -e "\033[0;34mcheck\033[0m:      Configures and checks the current workspace."
echo -e "\033[0;34mgraph\033[0m:      Graph the completed build timing."
echo -e "\033[0;34mlegal-info\033[0m: Legal information."
echo -e "\033[0;34mbr/*\033[0m:       Execute a buildroot command, ex: br/menuconfig."

# Display configuration-specific commands
for conf in "${SKIFF_CONFIGS[@]}"; do
	# Convert config name to environment variable format
	conf_var_prefix=$(echo "${conf}" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')

	# Get command list and paths variable names
	cmd_list_var="SKIFF_${conf_var_prefix}_COMMAND_LIST"
	cmd_paths_var="SKIFF_${conf_var_prefix}_COMMAND_PATHS"

	# Skip if no commands available for this config
	if [[ -z ${!cmd_list_var} ]]; then
		continue
	fi

	# Parse command list and paths
	cmd_list=(${!cmd_list_var})
	cmd_paths=(${!cmd_paths_var})

	# Print command section header
	echo ""
	echo -e "\e[0;31m\033[1m${conf} Commands\e[0m"

	# Display each command with its description
	for cmd in "${cmd_list[@]}"; do
		# Convert command name to environment variable format
		cmd_var=$(echo "${cmd}" | tr '[:lower:]' '[:upper:]' | sed -e 's#/#_#g')

		# Get command description
		description_var="SKIFF_${conf_var_prefix}_COMMAND_${cmd_var}_DESCRIP"
		description="${!description_var}"

		# Display command with description
		echo -e "\033[0;34mcmd/${conf}/${cmd}\033[0m: ${description}"
	done
done
