# Pine64 PinePhone

This configuration package `pine64/phone` compiles a Skiff base operating system
for the Pine64 PinePhone.

References: 

 - https://linux-sunxi.org/PinePhone
 - https://wiki.pine64.org/index.php?title=PinePhone 
 - https://www.ironrobin.net/pureos/git/clover/pinephone
 - https://gitlab.com/groups/postmarketOS/-/milestones/1
 - https://gitlab.com/postmarketOS/pmaports/-/tree/master/device/community/device-pine64-pinephone

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/phone,core/pinephone_neon
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section below for more info.

## Flashing

Skiff is easiest installed to a SD card. A tool can be used to flash the OS to
the internal EMMC once booted to the SD card. The PinePhone will boot from the
SD card if it is present and contains u-boot.

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

## KDE Neon

The `core/pinephone_neon` portion of SKIFF_CONFIG enables "Skiff Core" with
Mobile KDE Neon - a version of KDE optimized for mobile.

This image was built by importing the pinephone KDE Neon image to Docker with
some tweaks. An ~2Gb file will be downloaded at first boot from Docker Hub with
the pinephone KDE Neon base image.

