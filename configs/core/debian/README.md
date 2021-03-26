# Debian

> Base configuration for Debian.

## Introduction

This package `core/debian` includes a base system for Debian.

This example is for the Raspberry Pi 4.

The `SKIFF_CONFIG` comma-separated environment variable selects which
configuration layers should be merged together to configure the build.

```sh
$ make                             # lists all available layers
$ export SKIFF_CONFIG=pi/4,core/debian
$ make configure                   # configure the system
$ make compile                     # build the system
```

After you run `make configure` Skiff will remember what you selected in
`SKIFF_CONFIG`. The compile command instructs Skiff to build the system.

You can add your SSH public key to the target image by adding it to
`overrides/root_overlay/etc/skiff/authorized_keys/my-key.pub`, or by adding it
to your own custom configuration package.

Once the build is complete, it's time to flash the system to a SD card. You will
need to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ blkid                 # look for your SD card's device file
$ export PI_SD=/dev/sdz # make sure this is right!
$ make cmd/pi/common/format  # tell skiff to format the device
$ make cmd/pi/common/install # tell skiff to install the os
```

The device needs to be formatted only one time, after which, the install command
can be used to update the SkiffOS images without clearing the persistent state.
The persist partition is not touched in this step, so anything you save there,
including Docker state and system configuration, will not be modified.

## Desktop Environment

Debian core does not come with a desktop environment, for the purposes of being
as light as possible. To enable a desktop environment, ssh to the `core` user
and run `sudo apt update && sudo apt install -y task-xfce-desktop lightdm`

## Connecting to the System

If you need to add your SSH key after the system is configured, mount the
"persist" partition and save your `id_rsa.pub` at `skiff/keys/mykey.pub`.

Connect to the "core" user to get started:

```sh
$ ssh core@my-ip-address
$ apt update
# etc...
```

You can ssh to `root` to access the SkiffOS "shim" system.

Edit `/mnt/persist/skiff/core/config.yaml` to modify the mapping of users to
containers, create more containers, or modify the bind-mounts to storage.

