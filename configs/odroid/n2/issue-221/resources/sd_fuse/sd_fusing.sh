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
if [ ! -b $1 ]; then
    echo "$1 not found, unable to fuse bootloader."
    exit 1
fi

####################################
# fusing images

uboot_position=1
device=$1

# Get the U-Boot blob
if [ ! -f $ubootimg ]; then
  echo "U-Boot blob not found."
  exit 1
fi

#<u-boot fusing>
echo "u-boot fusing"
dd iflag=dsync oflag=dsync if=$ubootimg of=$device seek=$uboot_position bs=512 skip=1 seek=1 ${SD_FUSE_DD_ARGS}
dd iflag=dsync oflag=dsync if=$ubootimg of=$device seek=$uboot_position bs=1 count=444 ${SD_FUSE_DD_ARGS}

####################################
#<Message Display>
echo "U-boot image is fused successfully."
