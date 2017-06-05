#!/bin/bash
set -eo pipefail

if [ -d "${SKIFF_FINAL_CONFIG_DIR}" ]; then
  source ${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh
fi

cd ${SKIFF_BUILDROOT_DIR}
bash
