#!/bin/bash

echo "Creating disable serial console stamp..."
touch ${SKIFF_WORKSPACE_DIR}/output/images/.disable-serial-console

if [ -n "$BR2_TARGET_GENERIC_GETTY_PORT" ] ; then
    echo "Creating systemd mask for ${BR2_TARGET_GENERIC_GETTY_PORT}"
    ln -fs /dev/null "${TARGET_DIR}/etc/systemd/system/serial-getty@${BR2_TARGET_GENERIC_GETTY_PORT}.service"
fi

