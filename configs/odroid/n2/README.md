# Odroid N2

This configuration package series configures Buildroot to produce a BSP image for the
Odroid N2.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=odroid/n2,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will flash to a MicroSD card to boot. You will
need to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ export ODROID_SD=/dev/sdz # make sure this is right! (usually sdb)
$ make cmd/odroid/common/format  # tell skiff to format the device
$ make cmd/odroid/common/install # tell skiff to install the os
```

You only need to run the `format` step once. It will create the partition table.
The `install` step will overwrite the current Skiff installation on the card,
taking care to not touch any persistent data (from the persist partition). It's
safe to upgrade Skiff independently from your persistent data.

## Building an Image

It's possible to create a .img file instead of directly flashing a SD.

```sh
# must be root to use losetup
sudo bash
# set your skiff workspace
export SKIFF_WORKSPACE=odroid
# set the output path
export ODROID_IMAGE=./odroid.img
# make the image
make cmd/odroid/common/buildimage
```

The image can then be flashed to the target:

```
# change sdX to, for example, sdb
dd if=odroid.img of=/dev/sdX status=progress oflag=sync
```

This is equivalent to using the format and install scripts.

The persist partition will be resized to fill the available space on first boot.

## Booting to Emmc

The above steps for formatting + installing to a MicroSD card can be used with a
Emmc card instead without changes.

## Using Emmc for Persist

An alternative way to setup the N2 for storing data on the EMMC card is to:

 1. Flash & install to a MicroSD card as described above.
 2. Delete the "persist" partition from the MicroSD card.
 3. Create an ext4 partition labeled "persist" on the EMMC.
 4. Attach both the MicroSD and the EMMC to the Odroid N2.
 
The "boot" and "rootfs" partitions on the microSD card will be used for the
boot-up files, and the "persist" partition on the EMMC will be used for data.
