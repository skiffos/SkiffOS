# SkiffOS on Steam Deck

The configuration package **valve/deck** is for the **Steam Deck** by Valve.

Reference:

 - https://en.wikipedia.org/wiki/Steam_Deck
 - https://help.steampowered.com/en/faqs/view/69E3-14AF-9764-4C28
 - https://github.com/mikeroyal/Steam-Deck-Guide
 - https://steamdeck-packages.steamos.cloud/archlinux-mirror/sources/jupiter-beta/

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=valve/deck,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will flash to a MicroSD card to boot. You will
need to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ export INTEL_DESKTOP_DISK=/dev/sdz # make sure this is right! (usually sdb)
$ make cmd/intel/desktop/format  # tell skiff to format the device
$ make cmd/intel/desktop/install # tell skiff to install the os
```

You only need to run the `format` step once. It will create the partition table.
The `install` step will overwrite the current Skiff installation on the card,
taking care to not touch any persistent data (from the persist partition). It's
safe to upgrade Skiff independently from your persistent data.

## Boot Process

To access the boot menu, power on the device while holding volume-down.

Select the "EFI SD Card" to boot from the MicroSD.
