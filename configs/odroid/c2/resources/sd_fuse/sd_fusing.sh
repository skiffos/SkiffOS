#
# Copyright (C) 2011 Samsung Electronics Co., Ltd.
#              http://www.samsung.com/
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 as
# published by the Free Software Foundation.
#
####################################
set -x
set -eo pipefail

if [ -z $1 ]; then
    echo "usage: ./sd_fusing.sh <SD Reader's device file> <ubootimg>"
    exit 1
fi

ubootimg=$2
if [ ! -f $ubootimg ]; then
    echo "$ubootimg not found, unable to fuse bootloader."
    exit 1
fi

device=$1
if [ ! -b $device ]; then
    echo "$device not found, unable to fuse bootloader."
    exit 1
fi

bl1=../odroidc2-uboot-blobs/bl1.bin.hardkernel
if [ ! -f $bl1 ]; then
    echo "$bl1 not found, unable to fuse bootloader"
    exit 1
fi

####################################
# fusing images

uboot_position=1

# Get the U-Boot blob
if [ ! -f $ubootimg ]; then
  echo "U-Boot blob not found."
  exit 1
fi

#<u-boot fusing>
echo "u-boot fusing"
dd iflag=dsync oflag=dsync if=$bl1 of=$device bs=1 count=442 ${SD_FUSE_DD_ARGS}
dd iflag=dsync oflag=dsync if=$bl1 of=$device bs=512 skip=1 seek=1 ${SD_FUSE_DD_ARGS}
dd iflag=dsync oflag=dsync if=$ubootimg of=$device bs=512 seek=97 ${SD_FUSE_DD_ARGS}

####################################
#<Message Display>
echo "U-boot image is fused successfully."
