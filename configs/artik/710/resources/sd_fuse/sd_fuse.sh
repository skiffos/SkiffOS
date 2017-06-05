#!/bin/bash

# UBoot offsets
export BL1_OFFSET = "1"
export BL2_OFFSET = "129"
export TZSW_OFFSET = "769"
export UBOOT_OFFSET = "3841"
export ENV_OFFSET = "5889"

device="$1"
echo "BL1 fusing"
dd conv=notrunc if=./bl1-sdboot.img of=$device seek=$BL1_OFFSET bs=512 ${SD_FUSE_DD_ARGS}

echo "u-boot fusing"
dd conv=notrunc if=../singleimage-sdboot.bin of=$device bs=512 seek=$BL2_OFFSET ${SD_FUSE_DD_ARGS}

echo "u-boot params fusing"
dd conv=notrunc if=../params_sdboot.bin of=$device seek=$ENV_OFFSET ${SD_FUSE_DD_ARGS}

echo "U-boot image was fused successfully."
