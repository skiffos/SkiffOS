#!/bin/bash

nvidia_config_sh=""
boot_conf_enc=""
config_paths=( ${SKIFF_CONFIG_PATH} )
for confp in "${config_paths[@]}"; do
    conf_i_res="${confp}/resources"
    if [ -f $conf_i_res/nvidia/board-params.sh ]; then
        nvidia_config_sh="$conf_i_res/nvidia/board-params.sh"
    fi
    if [ -d $conf_i_res/nvidia/extlinux ]; then
        nvidia_extlinux_dir="$conf_i_res/nvidia/extlinux"
        boot_conf=""
        boot_conf_enc=""
    fi
    if [ -f $conf_i_res/boot-scripts/boot.txt ]; then
        boot_conf="$conf_i_res/boot-scripts/boot.txt"
        boot_conf_enc="yes"
        nvidia_extlinux_dir=""
    fi
done

if [ -z "$nvidia_config_sh" ]; then
    echo "Unable to find nvidia board params in skiff configs."
    exit 1
fi

if [ ! -f $boot_conf ] && [ ! -d "$nvidia_extlinux_dir" ]; then
    echo "Unable to find extlinux dir or boot.txt in skiff configs."
    exit 1
fi

export nvidia_config_sh
export nvidia_extlinux_dir
export boot_conf
export boot_conf_enc
