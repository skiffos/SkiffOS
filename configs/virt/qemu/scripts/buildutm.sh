#!/bin/bash
set -eo pipefail

# Directories and file setup
IMAGES_DIR="${BUILDROOT_DIR}/images"
UTM_DIR="${IMAGES_DIR}/skiffos.utm"
ROOTFS_FILE="${UTM_DIR}/Data/persist.qcow2"

# Set default root filesystem size if not provided
: "${ROOTFS_MAX_SIZE:=32G}"

# Ensure necessary directories exist
mkdir -p "${UTM_DIR}/Data"

# Copy necessary resources
cp "${ROOT_DIR}/resources/images/skiff-icon.png" "${UTM_DIR}/Data/skiff-icon.png"
cp "${IMAGES_DIR}/Image" "${UTM_DIR}/Data/Image"
cp "${IMAGES_DIR}/rootfs.cpio.lz4" "${UTM_DIR}/Data/rootfs.cpio.lz4"

# Create a sparse image if it does not exist
if [ ! -f "${ROOTFS_FILE}" ]; then
    qemu-img create -f qcow2 "${ROOTFS_FILE}" "${ROOTFS_MAX_SIZE}"
fi

# Function to generate a MAC address
# https://github.com/utmapp/UTM/blob/13664282a2a9fb239f62c5777cb45cabcce29fae/Configuration/UTMConfiguration%2BNetworking.m#L75-L85
generate_mac_address() {
    local mac=""
    for i in {1..6}; do
        local byte=$((RANDOM % 256))
        if [[ $i -eq 1 ]]; then
            byte=$((byte & 0xFC | 0x2)) # Ensure locally administered and unicast
        fi
        mac+=$(printf "%02X" $byte)
        [ $i -lt 6 ] && mac+=":"
    done
    echo "$mac"
}

# Configure UTM plist with a dynamic MAC address
cp "${SKIFF_CURRENT_CONF_DIR}/resources/utm-config.plist" "${UTM_DIR}/config.plist"
sed -i -e "s/REPLACEME_MAC_ADDRESS/$(generate_mac_address)/g" "${UTM_DIR}/config.plist"

# Echo completion status
echo "UTM environment setup complete."
