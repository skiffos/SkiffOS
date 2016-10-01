#!/bin/bash
export ROOT_DIR=$(pwd)
export SKIFF_DOCKER_ROOT=${ROOT_DIR}/docker
export SKIFF_DOCKER_MOUNT=${ROOT_DIR}/docker-mount
export SKIFF_CONFIGS_DIR=${ROOT_DIR}/configs 
export SKIFF_RESOURCES_DIR=${ROOT_DIR}/resources 
export SKIFF_BASE_CONFIGS_DIR=${ROOT_DIR}/configs-base 
export SKIFF_SCRIPTS_DIR=${ROOT_DIR}/scripts 
cd configs
source ../scripts/check_git_worktree.sh 
source ../scripts/maybe_recover_skiff_config.sh 
source ../scripts/enumerate_configs.sh >/dev/null 
export BUILDROOT_DEFAULT_DIR=${ROOT_DIR}/workspaces/default
export BUILDROOT_DIR=${ROOT_DIR}/workspaces/${SKIFF_WORKSPACE} 
export SKIFF_BUILDROOT_DIR=${ROOT_DIR}/workspaces/${SKIFF_WORKSPACE} 
export SKIFF_WORKSPACE_DIR=${ROOT_DIR}/workspaces/${SKIFF_WORKSPACE} 
export WORKSPACE_DIR=${ROOT_DIR}/workspaces/${SKIFF_WORKSPACE}
cd ../build
make $@
