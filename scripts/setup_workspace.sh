#!/usr/bin/env bash
# SkiffOS workspace setup script
# Creates and initializes the workspace directory structure
set -eo pipefail

# Enable command echo for debugging
set -x

# Initialize workspace directory if it doesn't exist or is incomplete
if [[ ! -d ${WORKSPACE_DIR} ]] || [[ ! -f "${WORKSPACE_DIR}/Makefile" ]]; then
	echo "Setting up Buildroot workspace at ${WORKSPACE_DIR}..."

	# Verify that buildroot directory exists
	if [[ ! -d ${BUILDROOT_DEFAULT_DIR} ]]; then
		echo "Error: Buildroot directory not found at ${BUILDROOT_DEFAULT_DIR}"
		exit 1
	fi

	# Setup the buildroot worktree
	pushd "${BUILDROOT_DEFAULT_DIR}" >/dev/null
	if ! make O="${WORKSPACE_DIR}" defconfig; then
		echo "Buildroot workspace setup failed. Check for errors above."
		exit 1
	fi
	popd >/dev/null

	echo "Buildroot workspace created successfully."
fi

# Create workspace overrides directory if it doesn't exist
if [[ ! -d ${SKIFF_WS_OVERRIDES_DIR} ]]; then
	echo "Creating workspace overrides directory..."
	mkdir -p "${SKIFF_WS_OVERRIDES_DIR}"
	cat >"${SKIFF_WS_OVERRIDES_DIR}/README" <<EOF
# ${SKIFF_WORKSPACE} Workspace Configuration

Place Skiff configuration files for the ${SKIFF_WORKSPACE} workspace here.
These files will override the default configurations for this workspace only.

For more information, see the SkiffOS documentation.
EOF
	echo "Workspace overrides directory created."
fi

# Create symbolic link for output directory
# This ensures that the output directory points to the workspace directory
if [[ ! -L "${WORKSPACE_DIR}/output" ]] || [[ "$(readlink "${WORKSPACE_DIR}/output")" != "${WORKSPACE_DIR}" ]]; then
	echo "Creating output symlink..."
	ln -sf "${WORKSPACE_DIR}" "${WORKSPACE_DIR}/output"
fi

echo "Workspace setup complete for ${SKIFF_WORKSPACE}."
