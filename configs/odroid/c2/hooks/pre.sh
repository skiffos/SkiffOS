#!/bin/bash
set -eo pipefail

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images

echo "Copying sd_fuse blobs..."
rsync -rav $SKIFF_CURRENT_CONF_DIR/resources/sd_fuse/ $IMAGES_DIR/hk_sd_fuse/

uboot_c2_postprocess()
{
	local t=$1
	$t/fip_create	--bl30  $t/gxb/bl30.bin \
			          --bl301 $t/gxb/bl301.bin \
			          --bl31  $t/gxb/bl31.bin \
			          --bl33  bl33.bin \
			          fip.bin
	$t/fip_create --dump fip.bin
	cat $t/gxb/bl2.package fip.bin > boot_new.bin
	rm -f u-boot.img
	$t/gxb/aml_encrypt_gxb --bootsig \
                          --input boot_new.bin \
                          --output u-boot.img
	rm -f u-boot.bin
	dd if=u-boot.img of=u-boot.bin bs=512 skip=96 status=none
}

echo "Building u-boot fip..."
cd ${IMAGES_DIR}
mkdir -p ./boot-fip
cd ./boot-fip
cp ../u-boot.bin bl33.bin
uboot_c2_postprocess ${IMAGES_DIR}/odroidc2-uboot-blobs/
cp u-boot.bin ${IMAGES_DIR}/u-boot-signed.bin.sd.bin
echo "Built u-boot fip for odroid c2."
