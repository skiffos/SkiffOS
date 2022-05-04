# ODROID

The configuration package `odroid/common` contains common configurations for the
Odroid series of boards by HardKernel. There are specific packages for each
board/series.

**If using the n2, set the boot switch to MMC.**

Reference:

 - https://github.com/tobetter/linux/commits/odroid-5.18.y
 - https://github.com/armbian/build/tree/master/patch/kernel/archive/meson64-5.17

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

## Board Compatibility

There are specific packages tuned to each model. The boards are all actively
tested by the developers unless otherwise noted.

| **Board**      | **Config Package** | Status       |
|----------------|--------------------|--------------|
| [c2]           | odroid/c2          |              |
| [c4]           | odroid/c4          | Reboot issue |
| [hc2]          | odroid/xu          |              |
| [hc4]          | odroid/hc4         | Reboot issue |
| [m1]           | odroid/m1          |              |
| [n2]           | odroid/n2          | Includes n2+ |
| [u] + u2       | odroid/u           | Discontinued |
| [xu3]          | odroid/xu          | Discontinued |
| [xu4] (+ xu4q) | odroid/xu          |              |

[u]: https://wiki.odroid.com/old_product/odroid-x_u_q/odroid_u3/odroid-u3
[xu3]: https://wiki.odroid.com/old_product/odroid-xu3/odroid-xu3
[xu4]: https://wiki.odroid.com/odroid-xu4/odroid-xu4
[hc2]: https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/
[n2]: https://www.hardkernel.com/shop/odroid-n2-with-4gbyte-ram-2/
[m1]: https://www.hardkernel.com/shop/odroid-m1-with-8gbyte-ram/
[c2]: https://www.hardkernel.com/shop/odroid-c2/
[c4]: https://www.hardkernel.com/shop/odroid-c4/
[hc4]: https://www.hardkernel.com/shop/odroid-hc4/

## SD Card Compatibility

The current SD cards used / tested by developers are:

 - PNY Turbo Performance 16GB High Speed MicroSDHC Class 10 UHS-1
 - SanDisk 128GB Extreme MicroSDXC UHS-I 
 - SanDisk 128GB MicroSDXC Nintendo Switch Edition
 - SanDisk Ultra MicroSDXC (Any)

The current cards that are known to **NOT** work are:

 - Intenso MicroSDXC Card, UHS-I, 64 GB

Some SD cards may not work as well with the Odroid hardware.

## Bootup Process

All Odroid boards use u-boot. U-boot is flashed to the beginning of the SD card,
before the first partition. It loads and executes a boot.ini configuration.

Note: there may be some binary bootloader blobs used that are provided by the
vendor & signed, and cannot be compiled by Skiff, depending on the board.

## Odroid N2

**If using the n2, set the boot switch to MMC.**

## Odroid HC4

**If using the hc4, petitboot must be bypassed.**

See the details in the [odroid/hc4](./hc4) docs.

On default, the HC4 boots from SPI, which contains petitboot. If the black
button on the bottom of the device (the "boot select" switch) is pressed, the
board will use u-boot from the MicroSD card.

## Acknowledgments

Thank you to [tobetter] for patching / testing the latest Linux kernels for the
Odroid series of boards.

The [SkiffOS Linux] fork restores support for older boards in newer kernels.

[tobetter]: https://github.com/tobetter/linux
[SkiffOS Linux]: https://github.com/skiffos/linux/tree/skiff-odroid-5.18.y
