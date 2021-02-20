# NASA F' Framework

> Flight software and embedded systems framework.

## Introduction

This package `core/nasa_fprime` enables a Skiff Core image based on NASA's
[Fprime] modular flight software and embedded systems framework.

[Fprime]: https://github.com/nasa/fprime

It is directly based on the upstream Dockerfile with some modifications to
improve the user experience as a core container.

Gentoo and other base operating systems are being tested, and may be used in the
future for the purpose of improved performance and CPU instruction coverage.

## Getting Started

This example is for the Raspberry Pi 4.

The `SKIFF_CONFIG` comma-separated environment variable selects which
configuration layers should be merged together to configure the build.

```sh
$ make                             # lists all available layers
$ export SKIFF_CONFIG=pi/4,core/nasa_fprime
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

NASA Fprime will be either downloaded from the container registry, or compiled
from source on the device, depending on image availability and user preferences.

## Connecting to the System

If you need to add your SSH key after the system is configured, mount the
"persist" partition and save your `id_rsa.pub` at `skiff/keys/mykey.pub`.

Connect to the "fprime" user to get started:

```sh
$ ssh fprime@my-ip-address
$ apt update
# etc...
```

You can ssh to `root` to access the SkiffOS "shim" system. The container will be
portable across devices of the same architecture. For example, a Ubuntu arm64
container will also work on a Jetson TX2.

Edit `/mnt/persist/skiff/core/config.yaml` to modify the mapping of users to
containers, create more containers, or modify the bind-mounts to storage.

