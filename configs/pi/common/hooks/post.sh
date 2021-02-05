#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/images
if [ -f ${IMAGES_DIR}/.disable-serial-console ]; then
    echo "skiff/noserial: disabling pi serial console"

    pushd ${IMAGES_DIR}/rpi-firmware
    RPI_CMDLINE=( $(cat cmdline.txt) )
    OUT_CMDLINE=()
    ANY_CHANGED=""
    for var in "${RPI_CMDLINE[@]}"; do
        # Ignore console=tty arguments
        if [[ "$var" == console* ]]; then
            ANY_CHANGED="true"
            continue
        fi
        OUT_CMDLINE+=("$var")
    done
    if [ -n "$ANY_CHANGED" ]; then
        echo "Changed rpi command line: ${OUT_CMDLINE[@]}"
        echo "${OUT_CMDLINE[@]}" > cmdline.txt
    fi
    popd
fi
