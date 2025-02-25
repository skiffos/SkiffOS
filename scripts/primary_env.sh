#!/usr/bin/env bash
# Primary environment setup for SkiffOS
# Sets up core environment variables and paths
set -eo pipefail

# Ensure consistent locale
export LC_ALL=C

# Set up core directory paths
export ROOT_DIR="$(pwd)"
export SKIFF_ROOT_DIR="${ROOT_DIR}"
export SKIFF_CONFIGS_DIR="${ROOT_DIR}/configs"
export SKIFF_WORKSPACES_DIR="${ROOT_DIR}/workspaces"
export SKIFF_OVERRIDES_DIR="${ROOT_DIR}/overrides"
export SKIFF_RESOURCES_DIR="${ROOT_DIR}/resources"
export SKIFF_BASE_CONFIGS_DIR="${ROOT_DIR}/configs-base"
export SKIFF_SCRIPTS_DIR="${ROOT_DIR}/scripts"

# Load version information
source ./scripts/skiff_version.sh

# Change to configs directory for relative path resolution
cd configs

# Load workspace and configuration information
source ../scripts/check_workspace.sh
source ../scripts/maybe_recover_skiff_config.sh
source ../scripts/enumerate_configs.sh >/dev/null

# Set up Buildroot directory paths
export BUILDROOT_DEFAULT_DIR="${ROOT_DIR}/buildroot"
export WORKSPACE_DIR="${ROOT_DIR}/workspaces/${SKIFF_WORKSPACE}"
export BUILDROOT_DIR="${WORKSPACE_DIR}"
export SKIFF_BUILDROOT_DIR="${WORKSPACE_DIR}"
export SKIFF_WORKSPACE_DIR="${WORKSPACE_DIR}"

# Change to build directory and forward make arguments
cd ../build
make "$@"
