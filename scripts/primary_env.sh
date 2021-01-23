#!/bin/bash
set -eo pipefail

export LC_ALL=C
export ROOT_DIR=$(pwd)
export SKIFF_ROOT_DIR=${ROOT_DIR}
export SKIFF_CONFIGS_DIR=${ROOT_DIR}/configs
export SKIFF_WORKSPACES_DIR=${ROOT_DIR}/workspaces
export SKIFF_OVERRIDES_DIR=${ROOT_DIR}/overrides
export SKIFF_RESOURCES_DIR=${ROOT_DIR}/resources
export SKIFF_BASE_CONFIGS_DIR=${ROOT_DIR}/configs-base
export SKIFF_SCRIPTS_DIR=${ROOT_DIR}/scripts
source ./scripts/skiff_version.sh
cd configs
source ../scripts/check_workspace.sh
source ../scripts/maybe_recover_skiff_config.sh
source ../scripts/enumerate_configs.sh >/dev/null
export BUILDROOT_DEFAULT_DIR=${ROOT_DIR}/buildroot
export WORKSPACE_DIR=${ROOT_DIR}/workspaces/${SKIFF_WORKSPACE}
export BUILDROOT_DIR=${WORKSPACE_DIR}
export SKIFF_BUILDROOT_DIR=${WORKSPACE_DIR}
export SKIFF_WORKSPACE_DIR=${WORKSPACE_DIR}
cd ../build
make $@
