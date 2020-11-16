# NVIDIA Jetson Nano

This configuration package configures Buildroot to produce a BSP image for the
Jetson Nano.

There are specific configurations for each board, see [readme](../).

References:

 - https://elinux.org/Jetson

Note: the Jetson Nano uses a custom u-boot script, similar to other Skiff
boards, and has a separate "format" and "install" script. This allows users to
update Skiff independently of the bootloader and partition layout and other
persistent data. The "install" step will not overwrite any persistent data in
the "persist" partition.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=jetson/nano
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system via USB. You will need
to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ export SKIFF_WORKSPACE=myworkspace
$ export NVIDIA_SD=/dev/sdX    # make sure this is right!
$ make cmd/jetson/nano/format  # tell skiff to format the device
$ make cmd/jetson/nano/install # tell skiff to install the os
```

The flashing process should look similar to [this
output](https://asciinema.org/a/V9wuudXPxC0nnImCjkFfmRWy4).

Note: updating Skiff requires running the "install" command (not the "format").
This will not overwrite any persistent data stored on the "persist" partition,
and will only replace files in the /boot directory. The "format" command creates
the initial system partition layout and installs u-boot and other firmware.
