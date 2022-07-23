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
ubootimg=$2
if [ ! -b $1 ]; then
    echo "$1 not found, unable to fuse bootloader."
    exit 1
fi

# Get the U-Boot blob
if [ ! -f $ubootimg ]; then
  echo "U-Boot blob not found."
  exit 1
fi

#<u-boot fusing>
echo "u-boot fusing"
dd conv=fsync,notrunc if=$ubootimg of=$device bs=512 seek=1

####################################
#<Message Display>
echo "U-boot image is fused successfully."
