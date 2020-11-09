# ODROID

The configuration package `odroid/common` contains common configurations for the
Odroid series of boards by HardKernel. There are specific packages for each
board/series.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=odroid/xu
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

You only need to run the `format` step once. It will create the partition table
and flash u-boot to the beginning of the drive. The `install` step will
overwrite the current Skiff installation on the card, taking care to not touch
any persistent data (from the persist partition). It's safe to upgrade Skiff
independently from your containerized environments.

Note: if Docker is upgraded between Skiff versions, we can't vouch for Docker
not breaking backwards compatibility at that time, however; this change would
usually only happen between major Skiff/Buildroot releases if so.

## Board Compatibility

There are specific packages tuned to each model. The boards are all actively
tested by the developers unless otherwise noted.

| **Board**       | **Config Package** | Status       |
| --------------- | -----------------  | --------     |
| [u] + u2        | odroid/u           | Discontinued |
| [xu3]           | odroid/xu          |              |
| [xu4] (+ xu4q)  | odroid/xu          |              |
| [hc2]           | odroid/xu          |              |
| [n2]            | odroid/c4          | Reboot issue |
| [c4]            | odroid/c4          | Reboot issue |

[u]: https://wiki.odroid.com/old_product/odroid-x_u_q/odroid_u3/odroid-u3
[xu4]: https://wiki.odroid.com/odroid-xu4/odroid-xu4
[hc2]: https://www.hardkernel.com/shop/odroid-hc2-home-cloud-two/
[n2]: https://www.hardkernel.com/shop/odroid-n2-with-4gbyte-ram-2/
[c4]: https://www.hardkernel.com/shop/odroid-c4/

## SD Card Compatibility

The current SD cards used / tested by developers are:

 - PNY Turbo Performance 16GB High Speed MicroSDHC Class 10 UHS-1
 - SanDisk 128GB Extreme MicroSDXC UHS-I 
 - SanDisk 64GB Ultra MicroSDXC UHS-I

The current cards that are known to **NOT** work are:

 - Intenso MicroSDXC Card, UHS-I, 64 GB

Some SD cards may not be compatible with the Odroid kernel.

## Bootup Process

All Odroid boards use u-boot. U-boot is flashed to the beginning of the SD card,
before the first partition. It loads and executes a boot.ini configuration.

Note: there may be some binary bootloader blobs used that are provided by the
vendor & signed, and cannot be compiled by Skiff, depending on the board.

## Known Issues

There are the following known issues:

 - Desktop environments / video rendering / MALI not tested yet.

The full desktop experience is not tested yet.

## Acknowledgments

(As of September, 2020):

Thank you to [armbian] and [tobetter] (and others) for patching / testing the
Linux kernel for the Odroid (meson and meson64) series of boards. The kernel
patches for the n2 and c4 are derived by computing the difference between
tobetter's latest version and the armbian version. Many configuration specifics
are referenced from the armbian repo.

[armbian]: https://github.com/armbian/build
[tobetter]: https://github.com/tobetter/linux

