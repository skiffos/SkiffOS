# Rockchip Rk3328 / ROCK64

This configuration package `pine64/rock64` compiles a Skiff base operating
system for a ROCK64 or similar rk3328 board.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

 ```sh
 $ export SKIFF_CONFIG=pine64/rock64,core/gentoo
 $ make configure                   # configure the system
 $ make compile                     # build the system
 ```

Once the build is complete, it's time to flash the system.

# Flashing

Skiff is easiest installed to a SD card.

Note: you may want to follow the "Erase SPI" steps below first.

These commands require root and may need to be run with `sudo bash`.

```
export SKIFF_WORKSPACE=myworkspace
export PINE64_SD=/dev/sdx # make sure this is correct - i.e. /dev/sdb
make cmd/pine64/common/format
make cmd/pine64/common/install
```

The "format" command creates the partition layout and installs u-boot. This only
needs to be run once. The "install" command copies the latest Image, dtb, boot
script, initramfs, and modules image to the boot and rootfs partitions. The root
system can be updated without touching the "persist" partition by running
"install" again whenever necessary.

# SPI

There is SPI memory which can be flashed with u-boot to provide additional boot
options without a SD card connected. You may want to erase this SPI to be sure
that the u-boot from Buildroot / SkiffOS is used, or flash an updated u-boot.

The [ayufan docs] for this process are available.

[ayufan docs]: https://github.com/ayufan-rock64/linux-build/blob/master/recipes/flash-spi.md

## Erase the SPI

Erasing the SPI contents will ensure that the u-boot from the SD card is used.

To zero the SPI, download the ayufan [u-boot-erase-spi-rock64] image.

[u-boot-erase-spi-rock64]: https://github.com/ayufan-rock64/linux-mainline-u-boot/releases/download/2021.07-ayufan-2021-gf128a779/u-boot-erase-spi-rock64.img.xz

Write the erase-spi image to a SD card (which will erase the card):

```sh
xz -k -d -c -v -T 3 u-boot-erase-spi-rock64.img.xz | dd of=/dev/<sdcard> bs=1M
```

Insert the microSD card, wait for it to boot. You should see the power LED flash
once per second. Then, remove the microSD card after about 30 seconds.
