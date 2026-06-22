#!/bin/bash

source "${SKIFF_FINAL_CONFIG_DIR}/bind_env.sh"

buildroot_args=("$@")
buildroot_args[0]="${buildroot_args[0]#*br/}"
buildroot_command="${buildroot_args[0]}"

case "$buildroot_command" in
  config|gconfig|menuconfig|nconfig|xconfig)
    menuconfig_baseline=$(mktemp)
    cp "${BUILDROOT_DIR}/.config" "$menuconfig_baseline" || exit
    trap 'rm -f "$menuconfig_baseline"' EXIT
    ;;
esac

cd "${BUILDROOT_DIR}" || exit
make "${buildroot_args[@]}"
buildroot_status=$?
if [ "$buildroot_status" -ne 0 ]; then
  exit "$buildroot_status"
fi

if [ -n "${menuconfig_baseline:-}" ]; then
  "${SKIFF_SCRIPTS_DIR}/write_buildroot_config_delta.sh" \
    "$menuconfig_baseline" \
    "${BUILDROOT_DIR}/.config" \
    "${SKIFF_WS_OVERRIDES_DIR}/buildroot/zz-buildroot-menuconfig-delta"
fi
