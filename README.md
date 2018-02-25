# SkiffOS

![](./resources/images/skiff.png)

## Introduction

Skiff is a extremely lightweight, minimal, in-memory operating system for embedded Linux devices. It is also an intuitive and modular configuration package manager for [Buildroot](http://buildroot.org). While any embedded system workflow can be implemented under Skiff, the default workflow is described below.

Skiff loads a small ~30MB image containing the Linux kernel and critical software (like networking/WiFi drivers) into RAM at boot-time, and never mounts the root filesystem. This allows the system to be powered off without a graceful shutdown with **no consequences** whatsoever. It offers **guaranteed boots and SSH reachability** which is ideal for embedded environments.

Skiff uses **docker** containers for user-space software. It can intelligently rebuild nearly any Docker image from the ground-up to support any CPU architecture. This allows for a highly modular and reliable system environment while retaining the **ease-of-use** and repeatability Docker containers offer.

Skiff optionally can rsync a filesystem overlay at boot time on top of the compiled image to allow for easy persistent tweaks to the file tree. This functionality is typically used to tweak the SSH or networking configuration.

Docker containers and images are stored in a separate persist filesystem partition. Thus, the mission-critical system is in-memory only, while the Docker partition can be repaired by the parent system automatically if necessary.

This repository includes configurations supporting a variety of embedded platforms, including Raspberry Pi and ODROID boards.

## Getting started

Building a system with Skiff is easy! This example will build a basic OS for a Pi 3.

You can type `make` at any time to see a status and help printout. Do this now, and look at the list of configuration packages. Select which ones you want, and set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ make                             # observe status output
$ SKIFF_CONFIG=pi/3 make configure # configure the system
$ make                             # check status again
$ make compile                     # build the system
```

After you run `make configure` Skiff will remember what you selected in `SKIFF_CONFIG`. The compile command instructs Skiff to build the system.

Once the build is complete, it's time to flash the system to a SD card. You will need to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ blkid                 # look for your SD card's device file
$ export PI_SD=/dev/sda # make sure this is right!
$ make cmd/pi/3/format  # tell skiff to format the device
$ make cmd/pi/3/install # tell skiff to install the os
```

After you format a card, you do not need to do so again. You can call the install command as many times as you want to update the system. The persist partition is not touched in this step, so anything you save there, including Docker state and system configuration, will not be touched in the upgrade.

Some operating systems are not compatible with the Skiff build system, due to the host not using glibc, or using some outdated or otherwise incompatible libraries for the fairly recent Skiff distribution.

If you encounter any errors related to host-* packages, you should [build with Docker](./docker-build).

## Workspaces

Workspaces allow you to configure and compile multiple systems in tandem.

Set `SKIFF_WORKSPACE` to the name of the workspace you want to use.

## System Configuration

Below are some common configuration tasks that may be necessary when configuring a new Skiff system.

### NetworkManager

Skiff uses NetworkManager to manage network connections.

Network configurations are loaded from `/etc/NetworkManager/system-connections` and from `skiff/connections` on the persist partition.

The configuration file format for these connections is [documented here](http://manpages.ubuntu.com/manpages/wily/man5/nm-settings-keyfile.5.html) with examples.

You can use `nmcli` on the device to manage `NetworkManager`, and any connection definitions written by `nmcli device wifi connect` or similar will automatically be written to the persist partition and persisted to future boots.

### WiFi with WPA Supplicant

If you chose, you may configure WiFi using `wpa_supplicant` configs instead of `NetworkManager`.

Skiff will load any wpa supplicant configs from the persist partition at `skiff/wifi`.

Here is an example file, `wpa_supplicant-wlan0.conf`. You can generate the entries using `wpa_passphrase MyNetwork MyNetworkPassword`:

```
ctrl_interface=/var/run/wpa_supplicant
eapol_version=1
ap_scan=1
fast_reauth=1

# Put networks here.
network={
  ssid="Example_Network"
  psk=1b1069f468f6f7b2492c659802676074c3e69026e79c4d64f2c6d3d5a0ae1866
}
```

### Hostname

You can set the hostname by placing the desired hostname in the `skiff/hostname` file on the persist partition. You could also set this in one of your config packages by writing the desired hostname to `/etc/hostname`.

### SSH Keys

The system on boot will generate the authorized_keys file for root.

It takes SSH public key files (`*.pub`) from these locations:

 - `/etc/skiff/authorized_keys` from inside the image
 - `skiff/keys` from inside the persist partition


## Performance Monitoring with Cadvisor

Performance monitoring and benchmarking is easy with the cadvisor tool.

The below command can be executed after sshing to the "root" user to start the performance monitoring UI on port 8080 on the device:

```bash
docker run \
 --volume=/:/rootfs:ro \
 --volume=/var/run:/var/run:rw \
 --volume=/sys:/sys:ro \
 --volume=/var/lib/docker/:/var/lib/docker:ro \
 --publish=8080:8080 \
 --detach=true \
 --name=cadvisor \
 braingamer/cadvisor-arm:latest
```

## Skiff Core

Users can work within a familiar, traditional, persistent OS environment if desired. This is called the "core" user within Skiff. If this feature is enabled:

 - On first boot, the system will build the **core** container image.
 - SSH connections to the **core** user are dropped into the Docker container seamlessly.
 - When building the container, the system automatically attempts to build an image compatible with the target.

This allows virtually any workflow to be migrated to Skiff with almost no effort. The config file structure is flexible, and allows for any number of containers, users, and images to be defined and built.

You may enable this by adding the config `skiff/core` to your `SKIFF_CONFIG` list.

To customize the core environment, edit the file at `skiff/core/config.yaml` on the persist partition. The default config will be placed there on first boot.

The default config can be overridden with a file at `/opt/skiff/coreenv/defconfig.yaml`.

## Configuration Packages

Skiff supports modular configuration packages. A configuration directory contains kernel configs, buildroot configs, system overlays, etc.

These packages are denoted as `namespace/name`. For example, an ODROID XU4 configuration would be `odroid/xu4`.

Configuration package directories should have a depth of 2, where the first directory is the category name and the second is the package name.

### Package Layout

A configuration package is laid out into the following directories:

```
├── buildroot:      buildroot configuration fragments
├── buildroot_ext:  buildroot extensions (extra packages)
├── extensions:     extra commands to add to the build system
│   └── Makefile
├── hooks:          scripts hooking pre/post build steps
│   ├── post.sh
│   └── pre.sh
├── kernel:         kernel configuration fragments
├── kernel_patches: kernel .patch files
├── metadata:       metadata files
│   ├── commands
│   ├── dependencies
│   ├── description
│   └── unlisted
├── resources:     files used by the configuration package
├── scripts:       any scripts used by the extensions
└── uboot_patches: u-boot .patch files
```

All files are optional.

### Out-of-tree configuration packages

You can set the following env variables to control this process:

 - `SKIFF_CONFIG_PATH_ODROID_XU4`: Set the path for the ODROID_XU4 config package. You can set this to add new packages or override old ones.
 - `SKIFF_EXTRA_CONFIGS_PATH`: Colon separated list of paths to look for config packages.
 - `SKIFF_CONFIG`: Name of skiff config to use, or comma separated list to overlay, with the later options taking precedence

These packages will be available in the Skiff system.

## Supported Systems

SkiffOS is based on Buildroot, which can compile operating systems for virtually any machine. Therefore, SkiffOS also works on nearly any architecture or board.

Here are the boards/systems currently supported by Skiff:

| **Board**       | **Config Package** | **Bootloader**       | **Kernel**      | **Notes**              |
| --------------- | -----------------  | -------------------- | --------------- | ---------------------- |
| [Odroid XU4]    | odroid/xu4         | ✔ U-Boot 2017.03 Src | ✔ 4.9.61        |                        |
| [Odroid HC1]    | odroid/xu4         | ✔ U-Boot 2017.03 Src | ✔ 4.9.61        |                        |
| [Odroid C2]     | odroid/c2          | ⚠ U-Boot 2015.01 Bin | ✔ 3.14.79       |                        |
| [Artik 710]     | artik/710          | ✔ U-Boot 2016.01 Src | ✔ 4.4.19        | ⚠ Experimental         |
| [Pi 3]          | pi/3               | N/A                  | ✔ 4.9.80        |                        |
| [Pi 1]          | pi/1               | N/A                  | ✔ 4.9.80        | ⚠ Untested             |
| [Pi 0]          | pi/0               | N/A                  | ✔ 4.9.80        |                        |
| [Docker Img]    | docker/standard    | N/A                  | N/A             | Run SkiffOS in Docker  |
| [OrangePi Lite] | orangepi/lite      | N/A                  | N/A             | ⚠ Untested             |
| [Odroid XU3]    | odroid/xu4         | ✔ U-Boot 2017.03 Src | ✔ 4.9.61        | ⚠ Discontinued         |
| [Odroid U]      | odroid/u           | ✔ U-Boot 2016.03 Src | ✔ mainline      | ⚠ Discontinued         |

[Odroid XU3]: http://www.hardkernel.com/main/products/prdt_info.php?g_code=G140448267127
[Odroid XU4]: http://www.hardkernel.com/main/products/prdt_info.php?g_code=G143452239825
[Odroid U]: http://www.hardkernel.com/main/products/prdt_info.php?g_code=G138745696275
[Odroid C2]: http://www.hardkernel.com/main/products/prdt_info.php?g_code=G145457216438
[Odroid HC1]: http://www.hardkernel.com/main/products/prdt_info.php?g_code=G150229074080
[Docker Img]: ./docker 
[OrangePi Lite]: http://orangepi.com/orange-pi-lite
[Pi 3]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[Pi 1]: https://www.raspberrypi.org/products/raspberry-pi-1-model-b/
[Pi 0]: https://www.raspberrypi.org/products/raspberry-pi-zero/
[Artik 710]: https://www.artik.io/modules/artik-710/

Adding support for a board involves creating a Skiff configuration package for the board, as described above.

If you have a board that is not yet supported by SkiffOS, please **open an issue,** and we will work with you to integrate and test the new platform.

## Support

If you encounter issues or questions at any point when using Skiff, please file a [GitHub issue](https://github.com/paralin/SkiffOS/issues/new).
