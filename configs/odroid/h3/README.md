# Odroid H3

This configuration package series configures Buildroot to produce a BSP image
for all of the Odroid H2 and H3 boards, including:

 - H2: Celeron J4105
 - H2+: Celeron J4115
 - H3: Celeron N5105
 - H3+: Pentium Silver N6005

This configuration uses intel/x64 and intel/desktop as a base and produces code
tuned for the Goldmont Plus CPU architecture.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=odroid/h3,skiff/core
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
taking care to not touch any persistent data (from the persist partition**. It's
safe to upgrade SkiffOS independently from your persistent data.

**Note that the Odroid H3 uses the intel/desktop format and install scripts.**

## Building an Image

It's possible to create a .img file instead of directly flashing a SD.

```sh
# must be root to use losetup
sudo bash
# set your skiff workspace
export SKIFF_WORKSPACE=odroid
# set the output path
export INTEL_DESKTOP_IMAGE=./odroid.img
# make the image
make cmd/intel/desktop/buildimage
```

The image can then be flashed to the target:

```
# change sdX to, for example, sdb
dd if=odroid.img of=/dev/sdX status=progress oflag=sync
```

This is equivalent to using the format and install scripts.

The persist partition will be resized to fill the available space on first boot.
