#!/bin/bash

set -e

WORK_DIR=$(mktemp -d)
EMPTY_WORK_DIR=$(mktemp -d)

function cleanup() {
  sync || true

  if [ -d "$WORK_DIR" ]; then
    rm -rf "$WORK_DIR" || true
  fi

  if [ -d "$EMPTY_WORK_DIR" ]; then
    rm -rf "$EMPTY_WORK_DIR" || true
  fi
}
trap cleanup EXIT

OUTPUT_DIR=$SKIFF_BUILDROOT_DIR/output/images
OUTPUT_IMAGE=$OUTPUT_DIR/sdcard.img
GENIMAGE_CFG=$SKIFF_CURRENT_CONF_DIR/resources/gen-image/genimage.cfg

ubootimg=$BUILDROOT_DIR/output/images/u-boot-sunxi-with-spl.bin
if [ ! -f "$ubootimg" ]; then
  echo "Cannot find u-boot, make sure Buildroot is done compiling."
  exit 1
fi

zimg_path=$OUTPUT_DIR/zImage
dtb_path=$(find "$OUTPUT_DIR/" -name '*.dtb' -print -quit)

if [ ! -f "$zimg_path" ]; then
  echo "zImage not found, make sure Buildroot is done compiling."
  exit 1
fi

if [ ! -f "$dtb_path" ]; then
  echo "dtb not found, make sure Buildroot is done compiling."
  exit 1
fi

source "$SKIFF_CURRENT_CONF_DIR/scripts/determine_config.sh"

sed -e "s|BOOT_SCRIPT_NAME|$(basename "$boot_conf"), boot.scr|g" \
  -e "s|KERNEL_IMAGE_NAME|$(basename "$zimg_path")|g" \
  -e "s|DTB_NAME|$(basename "$dtb_path")|g" \
  "$GENIMAGE_CFG" > "$OUTPUT_DIR/genimage.cfg"

rootfs_dir=$WORK_DIR/rootfs
persist_dir=$WORK_DIR/persist

mkdir -p "$rootfs_dir"
mkdir -p "$persist_dir"

if [ -d "$OUTPUT_DIR/rootfs_part" ]; then
  echo "Copying rootfs_part..."
  rsync -rav --no-perms --no-owner --no-group "$OUTPUT_DIR/rootfs_part/" "$rootfs_dir/"
fi

if [ -d "$OUTPUT_DIR/persist_part" ]; then
  echo "Copying persist_part..."
  rsync -rav --no-perms --no-owner --no-group "$OUTPUT_DIR/persist_part/" "$persist_dir/"
fi

echo "Compiling $(basename "$boot_conf")..."
cp "$boot_conf" "$OUTPUT_DIR/"
mkimage -A arm -C none -T script -d "$OUTPUT_DIR/$(basename "$boot_conf")" "$OUTPUT_DIR/boot.scr"

genimage \
  --rootpath "$WORK_DIR" \
  --tmppath "$EMPTY_WORK_DIR" \
  --inputpath "$OUTPUT_DIR" \
  --outputpath "$OUTPUT_DIR" \
  --config "$OUTPUT_DIR/genimage.cfg"

echo "Flashing u-boot..."
dd if="$ubootimg" of="$OUTPUT_IMAGE" conv=fsync,notrunc bs=1024 seek=8
