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

if [ -z $1 ]
then
    echo "usage: ./sd_fusing.sh <SD Reader's device file> <ubootimg>"
    exit 0
fi
ubootimg=$2

device=$1

if [ -b $device ]
then
    echo "$device reader is identified."
else
    echo "$device is NOT identified."
    exit 0
fi

####################################
# fusing images
uboot_position=8

# Get the U-Boot blob
if [ ! -f $ubootimg ]; then
  echo "U-Boot blob not found."
  exit 1
fi

#<u-boot fusing>
echo "u-boot fusing"
dd iflag=dsync oflag=dsync if=$ubootimg of=$device seek=$uboot_position ${SD_FUSE_DD_ARGS}

####################################
#<Message Display>
echo "U-boot image is fused successfully."
