#!/usr/bin/env bash
# SkiffOS workspace cleanup script
# Cleans up the workspace and related directories
set -eo pipefail

# Check if workspace exists
if [[ ! -d ${WORKSPACE_DIR} ]]; then
	echo "Workspace directory does not exist, nothing to clean up."
	exit 0
fi

# Prompt for confirmation in interactive mode
if [[ -z ${SKIFF_NO_INTERACTIVE} ]]; then
	echo "This will clean and delete your current workspace: ${WORKSPACE_DIR}"
	read -p "Are you sure you want to proceed? [y/N] " -n 1 -r
	echo # Move to a new line

	if ! [[ $REPLY =~ ^[Yy]$ ]]; then
		echo "Operation cancelled."
		exit 1
	fi
fi

# Ask about ccache unless already specified or in non-interactive mode
if [[ -z ${SKIFF_KEEP_CCACHE} ]] && [[ -z ${SKIFF_NO_INTERACTIVE} ]]; then
	echo "The compiler cache can be preserved to speed up future builds."
	read -p "Do you want to also clear the compiler cache? [y/N] " -n 1 -r
	echo # Move to a new line

	if ! [[ $REPLY =~ ^[Yy]$ ]]; then
		export SKIFF_KEEP_CCACHE="true"
		echo "Compiler cache will be preserved."
	else
		echo "Compiler cache will be cleared."
	fi
fi

# Clean up workspace based on type
echo "Cleaning workspace: ${SKIFF_WORKSPACE}..."
if [[ ${SKIFF_WORKSPACE} != "default" ]]; then
	# For non-default workspaces, completely remove the directory
	rm -rf "${WORKSPACE_DIR}"
	echo "Workspace directory removed."
else
	# For default workspace, just clean buildroot
	echo "Cleaning default workspace with 'make clean'..."
	cd "${WORKSPACE_DIR}"
	rm -f .config || true
	if ! make clean; then
		echo "Warning: 'make clean' failed, attempting to continue."
	fi
fi

# Delete the configuration directory
if [[ -d ${SKIFF_FINAL_CONFIG_DIR} ]]; then
	echo "Removing configuration directory: ${SKIFF_FINAL_CONFIG_DIR}"
	rm -rf "${SKIFF_FINAL_CONFIG_DIR}"
fi

# Delete the compiler cache if requested
if [[ -z ${SKIFF_KEEP_CCACHE} ]] && [[ -d ${BR2_CCACHE_DIR} ]]; then
	echo "Removing compiler cache: ${BR2_CCACHE_DIR}"
	rm -rf "${BR2_CCACHE_DIR}"
fi

echo "Workspace cleanup completed successfully."
