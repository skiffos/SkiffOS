# Freescale Wandboard

This configuration package series configures Buildroot to produce a BSP image for the
Freescale Wandboard ARMv7 Cortex-A9 Board (and similar).

References:

 - https://archlinuxarm.org/platforms/armv7/freescale/wandboard
 - Buildroot: wandboard_defconfig
 
# Flashing

Skiff is easiest installed to a SD card.

These commands require root and may need to be run with `sudo bash`.

```
export SKIFF_WORKSPACE=wandboard
export WANDBOARD_SD=/dev/sdx # make sure this is correct - i.e. /dev/sdb
make cmd/freescale/wandboard/format
make cmd/freescale/wandboard/install
```

The "format" command creates the partition layout and installs u-boot. This only
needs to be run once. The "install" command copies the latest Image, dtb, boot
script, initramfs, and modules image to the boot and rootfs partitions. The root
system can be updated without touching the "persist" partition by running
"install" again whenever necessary.


## Building an Image

It's possible to create a .img file instead of directly flashing a SD.

```sh
# must be root to use losetup
sudo bash
# set your skiff workspace
export SKIFF_WORKSPACE=wandboard
# set the output path
export WANDBOARD_IMAGE=./wandboard.img
# make the image
make cmd/freescale/wandboard/buildimage
```

The image can then be flashed to the target:

```
# change sdX to, for example, sdb
dd if=wandboard.img of=/dev/sdX status=progress oflag=sync
```

This is equivalent to using the format and install scripts.

The persist partition will be resized to fill the available space on first boot.
