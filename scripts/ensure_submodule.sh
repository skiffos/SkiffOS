#!/usr/bin/env bash
# SkiffOS submodule initialization script
# Ensures the buildroot submodule is properly initialized
set -eo pipefail

# Verify we're in the project root directory
if [[ ! -d ${ROOT_DIR} ]]; then
	echo "Error: ROOT_DIR environment variable not set or invalid."
	exit 1
fi

# Change to the root directory
cd "${ROOT_DIR}"

# Check if buildroot submodule is missing or incomplete
if [[ ! -d "./buildroot" ]] || [[ ! -f "./buildroot/Makefile" ]]; then
	echo "Buildroot submodule not initialized. Initializing..."

	# Check if git is available
	if ! command -v git &>/dev/null; then
		echo "Error: git command not found. Please install git."
		exit 1
	fi

	# Initialize buildroot submodule
	if ! git submodule update --init --recursive; then
		echo "Error: Failed to initialize buildroot submodule."
		echo "Please check your network connection and git repository access."
		exit 1
	fi

	echo "Buildroot submodule initialized successfully."
else
	echo "Buildroot submodule already initialized."
fi
