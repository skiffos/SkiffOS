# Odroid HC4

This configuration targets the Odroid HC4.

**Petitboot must be bypassed to boot this board.**

See the [common config](../) for more information.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=odroid/hc4,skiff/core
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

You will then need to disable Petitboot:

## Disabling Petitboot

On default, the HC4 boots from SPI, which contains petitboot. If the black
button on the bottom of the device (the "boot select" switch) is pressed, the
board will use u-boot from the MicroSD card.

To permanently disable petitboot:

 1. Attach a display & keyboard to the device.
 2. Power on the board.
 3. Go to "Exit to shell" and enter these commands:
 
```sh
flash_eraseall /dev/mtd0
flash_eraseall /dev/mtd1
flash_eraseall /dev/mtd2
flash_eraseall /dev/mtd3
```
 
Alternatively, boot to SkiffOS using the black button on the bottom of the
device while booting, then use the following command to erase the SPI:

```sh
flash_erase /dev/mtd0 0 0
```
