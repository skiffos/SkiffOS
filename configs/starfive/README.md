# Starfive

The configuration package `starfive/common` contains common configurations for
the Starfive series of RISC-V boards.

Reference:

 - https://github.com/buildroot/buildroot/tree/master/board/beaglev

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=starfive/visionfive,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will flash to a MicroSD card to boot. You will
need to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ export STARFIVE_SD=/dev/sdz # make sure this is right! (usually sdb)
$ make cmd/starfive/common/format  # tell skiff to format the device
$ make cmd/starfive/common/install # tell skiff to install the os
```

You only need to run the `format` step once. It will create the partition table.
The `install` step will overwrite the current Skiff installation on the card,
taking care to not touch any persistent data (from the persist partition**. It's
safe to upgrade Skiff independently from your persistent data.

## Flashing the Bootloader

**The VisionFive u-boot must be flashed to setup the board.**

Instructions:

 1. Connect a TTL UART cable to pin 8 (TX), 10 (RX) and 14 (GND).
 2. Access the uart with `minicom -D /dev/ttyUSB0 -b 115200`.
 3. Press ctrl + a, then "O" to enter minicom Xmodem settings.
 4. Configure minicom to send `fw_payload.bin.out`.
 5. Exit the minicom settings.
 6. Insert your SD card.
 7. Power-up the board.
 8. On the UART terminal, interrupt boot by pressing any key.
 9. Press 0 to update uboot, then enter.
 10. You will see a series of "C" characters.
 11. Press Ctrl + A, then Z, then press "S" to send the file w/ Xmodem.
 12. Wait until the transfer is completed.
 13. Power off & restart the board w/ SD card connected.

If all went successfully, the system will boot into U-boot, then SkiffOS!

## Board Compatibility

There are specific packages tuned to each model. The boards are all actively
tested by the developers unless otherwise noted.

| **Board**    | **Config Package**    | Notes                 |
|--------------|-----------------------|-----------------------|
| [visionfive] | [starfive/visionfive] | SiFive U74 RV64GC     |
| [beaglev]    | [starfive/visionfive] | Compatible w/ BeagleV |

[beaglev]: https://beagleboard.org/static/beagleV/beagleV.html
[visionfive]: https://ameridroid.com/products/visionfive-starfive
[starfive/visionfive]: ./visionfive

## SD Card Compatibility

The current SD cards used / tested by developers are:

 - SanDisk Ultra MicroSDXC (Any)

The current cards that are known to **NOT** work are:

 - Intenso MicroSDXC Card, UHS-I, 64 GB

Some SD cards may not work as well with the Starfive hardware.

## Kernel

The kernel used is the [StarFive VisionFive] kernel.

[StarFive VisionFive]: https://github.com/starfive-tech/linux/tree/visionfive

Mirrored [here](https://github.com/skiffos/linux/tree/visionfive).

## Flashing low-level bootloaders

The boards come factory-flashed with compatible low-level bootloaders
"secondboot" and "ddrinit." While not strictly necessary, you can override them
with the ones compiled by Buildroot:

 1. Follow the Flashing the bootloader steps through step 8.
 2. Enter "root@s5t" instead of "0"
 3. Press 0 and send the bootloader-JH7100-buildroot.bin.out file.
 4. Press 1 and send the ddrinit-2133-buildroot.bin.out

Note: if this process fails, you will need to use a recovery process with a
separate UART to fix it, so be careful.

The process is documented [on seeedstudio wiki] in the section "Recover the
bootloader." The instructions make use of a jh7100-recover tool, compiled as
part of this config as a host tool: at `host/bin/jh7100-recover`.

[on seeedstudio wiki]: https://wiki.seeedstudio.com/BeagleV-Update-bootloader-ddr-init-boot-uboot-Recover-bootloader/

## Acknowledgments

This configuration is based on the "beaglev" defconfig in Buildroot mainline.
