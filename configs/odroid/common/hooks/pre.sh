#!/bin/bash
set -eo pipefail

echo "Building modules image..."
${SKIFF_CURRENT_CONF_DIR}/scripts/make_modules_image.sh
