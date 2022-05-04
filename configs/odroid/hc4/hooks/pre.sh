#!/bin/bash

IMAGES_DIR=${SKIFF_BUILDROOT_DIR}/output/images

echo "Copying sd_fuse script..."
rsync -rav $SKIFF_CURRENT_CONF_DIR/resources/sd_fuse/ $IMAGES_DIR/hk_sd_fuse/

# this helper function includes postprocess for u200 and its variants.
# $1 PATH for uboot blob repo
# $2 family g12a or g12b
# source: https://raw.githubusercontent.com/armbian/build/master/config/sources/families/include/meson64_common.inc
uboot_g12_postprocess()
{
	$1/blx_fix.sh $1/bl30.bin \
		      zero_tmp \
		      bl30_zero.bin \
		      $1/bl301.bin \
		      bl301_zero.bin \
		      bl30_new.bin bl30

	$1/blx_fix.sh $1/bl2.bin \
		      zero_tmp \
		      bl2_zero.bin \
		      $1/acs.bin \
		      bl21_zero.bin \
		      bl2_new.bin bl2

	$1/aml_encrypt_$2 --bl30sig \
			    --input bl30_new.bin \
			    --output bl30_new.bin.g12.enc \
			    --level v3
	$1/aml_encrypt_$2 --bl3sig \
			    --input bl30_new.bin.g12.enc \
			    --output bl30_new.bin.enc \
			    --level v3 --type bl30
	$1/aml_encrypt_$2 --bl3sig \
			    --input $1/bl31.img \
			    --output bl31.img.enc \
			    --level v3 --type bl31
	$1/aml_encrypt_$2 --bl3sig \
			    --input bl33.bin \
			    --compress lz4 \
			    --output bl33.bin.enc \
			    --level v3 --type bl33
	$1/aml_encrypt_$2 --bl2sig \
			    --input bl2_new.bin \
			    --output bl2.n.bin.sig
	if [ -e $1/lpddr3_1d.fw ]
		then
			$1/aml_encrypt_$2 --bootmk --output u-boot-signed.bin \
			--bl2 bl2.n.bin.sig \
			--bl30 bl30_new.bin.enc \
			--bl31 bl31.img.enc \
			--bl33 bl33.bin.enc \
			--ddrfw1 $1/ddr4_1d.fw \
			--ddrfw2 $1/ddr4_2d.fw \
			--ddrfw3 $1/ddr3_1d.fw \
			--ddrfw4 $1/piei.fw \
			--ddrfw5 $1/lpddr4_1d.fw \
			--ddrfw6 $1/lpddr4_2d.fw \
			--ddrfw7 $1/diag_lpddr4.fw \
			--ddrfw8 $1/aml_ddr.fw \
			--ddrfw9 $1/lpddr3_1d.fw \
			--level v3
	else
		$1/aml_encrypt_$2 --bootmk  --output u-boot-signed.bin \
			--bl2 bl2.n.bin.sig \
			--bl30 bl30_new.bin.enc \
			--bl31 bl31.img.enc \
			--bl33 bl33.bin.enc \
			--ddrfw1 $1/ddr4_1d.fw \
			--ddrfw2 $1/ddr4_2d.fw \
			--ddrfw3 $1/ddr3_1d.fw \
			--ddrfw4 $1/piei.fw \
			--ddrfw5 $1/lpddr4_1d.fw \
			--ddrfw6 $1/lpddr4_2d.fw \
			--ddrfw7 $1/diag_lpddr4.fw \
			--ddrfw8 $1/aml_ddr.fw \
			--level v3
	fi
}

echo "Building u-boot fip..."
cd ${IMAGES_DIR}
mkdir -p ./boot-fip
cd ./boot-fip
cp ../u-boot.bin bl33.bin
uboot_g12_postprocess ${IMAGES_DIR}/amlogic-boot-fip/ g12a
cp u-boot-signed.bin.sd.bin ${IMAGES_DIR}/
echo "Built u-boot fip for odroid hc4."
