#!/bin/bash
set -eo pipefail

# NOTE: Remember to also apply any changes to apps/balena.

echo "[apps/docker] Merging Docker daemon.json fragments..."

SRC_DJSON="$SKIFF_CURRENT_CONF_DIR/resources/docker/daemon.json"
TARGET_DJSON="$SKIFF_WORKSPACE_DIR/target/etc/docker/daemon.json"
TARGET_DJSON_DIR=$(dirname "${TARGET_DJSON}")

# Create the target directory if it does not exist
if [ ! -d "${TARGET_DJSON_DIR}" ]; then
    mkdir -p "${TARGET_DJSON_DIR}"
fi

# If the base config exists, merge it together
if [ -f "${TARGET_DJSON}" ]; then
    # Merge with jq, buildroot provides it with host-jq
    jq -s '.[0] * .[1]' "${SRC_DJSON}" "${TARGET_DJSON}" > "${TARGET_DJSON}.tmp"
    mv "${TARGET_DJSON}.tmp" "${TARGET_DJSON}"
else
    cp "${SRC_DJSON}" "${TARGET_DJSON}"
fi

# Determine the list of fragments from SKIFF_CONFIG list
# Configuration fragments are loaded from resources/docker/daemon.json.d/*.json
# Packages later in the SKIFF_CONFIG list override those earlier in the list
SRC_FRAGMENTS=()
config_paths=( ${SKIFF_CONFIG_PATH} )
for (( idx=${#config_paths[@]}-1 ; idx>=0 ; idx-- )) ; do
    config_dir="${config_paths[idx]}/resources/docker/daemon.json.d"
    if [ -d "$config_dir" ]; then
        # Add fragments to SRC_FRAGMENTS
        for fragment in "$config_dir"/*.json; do
            SRC_FRAGMENTS+=("$fragment")
        done
    fi
done

# Merge all fragments
for f in "${SRC_FRAGMENTS[@]}" ; do
    echo "[apps/docker] Merging docker.json fragment $(basename "${f}")..."
    jq -s '.[0] * .[1]' "${TARGET_DJSON}" "${f}" > "${TARGET_DJSON}.tmp"
    mv "${TARGET_DJSON}.tmp" "${TARGET_DJSON}"
done
