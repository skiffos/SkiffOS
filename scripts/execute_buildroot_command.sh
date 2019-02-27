#!/bin/bash

source ${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh
cd ${BUILDROOT_DIR} && make ${@#*br/}
