# Intel Desktop

This configuration package supports running SkiffOS on any Intel Desktop PC.

Additional kernel options are enabled to support a generic set of machines.
These modules could be disabled in other packages to trim down the OS size.

This setup uses a single SKIFFOS boot/rootfs/persist partition.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=intel/desktop,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will flash to a disk to boot. You will need to
`sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ export INTEL_DESKTOP_DISK=/dev/sdz # make sure this is right! (usually sdb)
$ make cmd/intel/desktop/format  # create the partition layout
$ make cmd/intel/desktop/install # install skiffos files
```

You only need to run the `format` step once. It will create the partition table.
The `install` step will overwrite the current Skiff installation on the card,
taking care to not touch any persistent data (from the persist partition). It's
safe to upgrade SkiffOS independently from your persistent data.

## Building an Image

It's possible to create a .img file instead of directly flashing a SD.

```sh
# must be root to use losetup
sudo bash
# set your skiff workspace
export SKIFF_WORKSPACE=default
# set the output path
export INTEL_DESKTOP_IMAGE=./intel-desktop-image.img
# make the image
make cmd/intel/desktop/buildimage
```

The image can then be flashed to the target:

```
# change sdX to, for example, sdb
dd if=intel-desktop-image.img of=/dev/sdX status=progress oflag=sync
```

This is equivalent to using the format and install scripts.

The persist partition will be resized to fill the available space on first boot.
