#!/bin/bash

OUTPUT_DIR=`pwd`

print_usage()
{
	echo "-h/--help         Show help options"
	echo "-o       Specify directory of output files"
	exit 0
}

parse_options()
{
	for opt in "$@"
	do
		case "$opt" in
			-h|--help)
				print_usage
				shift ;;
			-o)
				OUTPUT_DIR="$2"
				shift ;;
			*)
				shift ;;
		esac
	done
}

parse_options "$@"

CHECK_FIP=`cat $OUTPUT_DIR/partmap_emmc.txt | grep "fip-secure"`

if [ "$CHECK_FIP" != "" ];then
	ARTIK710=true
else
	ARTIK710=false
fi

echo "Fusing bootloader binaries..."
sudo fastboot flash partmap $OUTPUT_DIR/partmap_emmc.txt
sudo fastboot flash 2ndboot $OUTPUT_DIR/bl1-emmcboot.img
if $ARTIK710; then
	sudo fastboot flash fip-loader $OUTPUT_DIR/fip-loader-emmc.img
	sudo fastboot flash fip-secure $OUTPUT_DIR/fip-secure.img
	sudo fastboot flash fip-nonsecure $OUTPUT_DIR/fip-nonsecure.img
else
	sudo fastboot flash bootloader $OUTPUT_DIR/singleimage-emmcboot.bin
fi
sudo fastboot flash env $OUTPUT_DIR/params.bin

echo "Fusing boot image..."
sudo fastboot flash boot $OUTPUT_DIR/boot.img
echo "Fusing modules image..."
sudo fastboot flash modules $OUTPUT_DIR/modules.img
echo "Fusing rootfs image..."

sudo fastboot flash setenv $OUTPUT_DIR/partition.txt
sudo fastboot flash -S 0 rootfs $OUTPUT_DIR/rootfs.img

sudo fastboot reboot

echo "Fusing done"
echo "You have to resize the rootfs after first booting"
echo "Run $ resize2fs /dev/mmcblk0p3"
