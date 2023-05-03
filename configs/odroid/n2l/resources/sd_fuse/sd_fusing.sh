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

device=$1
if [ ! -b $device ]; then
    echo "$1 not found, unable to write bootloader."
    exit 1
fi

ubootimg=$2
if [ ! -f $ubootimg ]; then
  echo "U-Boot blob not found: $ubootimg"
  exit 1
fi

# https://github.com/LibreELEC/LibreELEC.tv/blob/7/projects/Amlogic/bootloader/mkimage#L8
echo "u-boot fusing"
dd conv=fsync,notrunc if=$ubootimg of=$device bs=1 count=440 ${SD_FUSE_DD_ARGS}
dd conv=fsync,notrunc if=$ubootimg of=$device bs=512 skip=1 seek=1 ${SD_FUSE_DD_ARGS}

echo "U-boot image was written successfully."
