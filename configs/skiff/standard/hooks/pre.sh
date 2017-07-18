#!/bin/bash

mkdir -p ${SKIFF_BUILDROOT_DIR}/output/images/resources
rm ${SKIFF_BUILDROOT_DIR}/output/target/usr/lib/systemd/system/network-online.target.wants || true
