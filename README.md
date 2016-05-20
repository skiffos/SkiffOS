# SkiffOS

![](http://i.imgur.com/XqpQJEm.png)

Skiff is an extremely lightweight, minimal, in-memory operating system for embedded Linux devices.

Skiff loads a small ~30MB image containing the Linux kernel and critical software (like networking/WiFi drivers) into RAM at boot-time, and never mounts the root filesystem. This allows the system to be powered off without a graceful shutdown with **no consequences** whatsoever. It offers **guaranteed boots and SSH reachability** which is ideal for embedded environments.

Skiff uses **docker** containers for user-space software. It can intelligently rebuild nearly any Docker image from the ground-up to support any CPU architecture. This allows for a highly modular and reliable system environment while retaining the **ease-of-use** and repeatability Docker containers offer.

Skiff optionally can rsync a filesystem overlay at boot time on top of the compiled image to allow for easy persistent tweaks to the file tree. This functionality is typically used to tweak the SSH or networking configuration.

Docker containers and images are stored in a "layer" filesystem partition. Thus, the mission-critical system is in-memory only and guaranteed to work, while the Docker partition can be less reliable.

The Setup
========

Skiff is made up of the following components:

 - [**Buildroot**](http://buildroot.org) compiles the Kernel, Init System, etc. from source and vendors them into a single image.
 - **SkiffOS** includes the Buildroot configuration, boot scripts, and general setup.
 - **Make** - the Makefile and scripts in this repository make building a system easy.

This repository also includes reference setups for ODROID devices.

Runtime Process
===============

Here's what happens when a Skiff system boots:

 - **Bootloader**: the u-boot (or similar) boot-loader executes, loading the OS image into RAM and executing the kernel.
 - **Kernel Load**: any required kernel modules are inserted.
 - **Networking Init**: the networking subsystem is initialized and configured.
 - **Docker Init**: the Docker partition is mounted and the daemon launched.

WiFi
====

You can configure WiFi at OS build time or at runtime. It's recommended to have a configuration package with your WiFi settings, but you might want to tweak them later.

Skiff will load any wpa supplicant configs from the persist partition at `skiff/wifi`.

Here is an example file, `wpa_supplicant_wlan0.conf`. You can generate the entries using `wpa_passphrase MyNetwork MyNetworkPassword`:

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

Static IP
=========

To customize the network configuration for an interface, place a network file into the persist drive at `skiff/network` or add in one of your configs a file at `/etc/systemd/network/wlan0.network`

For example, `wlan0.network`:

```
[Match]
Name=wlan0

[Network]
DNS=8.8.8.8
Address=192.168.1.119/24
Gateway=192.168.1.1
```

Access
======

The system on boot will generate the authorized_keys file for root.

It takes SSH public key files (`*.pub`) from these locations:

 - `/etc/skiff/authorized_keys` from inside the image
 - `skiff/keys` from inside the persist partition

Crew App Management
===================

Optionally, Skiff can use a minimal fork of Dokku named [Crew](http://github.com/paralin/crew) to build and manage Docker-based apps. Users can simply Git Push to the system to trigger a docker image build and deploy to the embedded environment. See the Crew repository for additional details.

User Environment Containers
===========================

Users can work within a familiar, traditional, persistent OS environment if desired. This is called the "core" user within Skiff. If this feature is enabled:

 - On first boot, the system will build the **core** container image.
 - SSH connections to the **core** user are dropped into the Docker container seamlessly.

This allows virtually any workflow to be migrated to Skiff with almost no effort.

You may enable this by adding the config `skiff/core` to your `SKIFF_CONFIG` list.

To customize the core environment, add another config that places a Dockerfile and any associated files in the root filesystem at /opt/skiff/coreenv/user

You can also customize the core environment by placing a Dockerfile and any associated files on the persist partition at `skiff/coreenv`.

Note that the `CMD` will be overridden. If you would like to specify a script to run on container start you can place it at /core-startup.sh in the container.

Make sure `/core-startup.sh` actually exits as all connections into the container will be held until it finishes.

A subdirectory called "core" of the persistent drive will be mounted to /mnt/core. You can use your startup script to simlink this anywhere you want.

Configuration Packages
======================

![](http://i.imgur.com/y3KbMqA.png)

Skiff supports modular configuration packages. A configuration directory contains kernel configs, buildroot configs, system overlays, etc.

These packages are denoted as `namespace/name`. For example, an ODROID XU4 configuration would be `odroid/xu4`.

Configuration package directories should have a depth of 2, where the first directory is the category name and the second is the package name.

You can set the following env variables to control this process:

 - `SKIFF_CONFIG_PATH_ODROID_XU4`: Set the path for the ODROID_XU4 config package. You can set this to add new packages or override old ones.
 - `SKIFF_EXTRA_CONFIGS_PATH`: Colon separated list of paths to look for config packages.
 - `SKIFF_CONFIG`: Name of skiff config to use, or comma separated list to overlay, with the later options taking precedence

These packages will be available in the Skiff system.

Workspaces
==========

Workspaces allow you to configure and compile multiple Buildroot trees in tandem.

Set `SKIFF_WORKSPACE` to the name of the workspace you want to use.

Other Env Variables
===================

Here are some other unmentioned env variables:

 - `SKIFF_NO_INTERACTIVE`: Auto-confirm all interactive prompts

Example: Odroid XU4
==================

As an example, here's how to build SkiffOS for the ODROID XUr.

Set the config setting `SKIFF_CONFIG` and the workspace `SKIFF_WORKSPACE` and kick off the build:

```
export SKIFF_WORKSPACE=tutorial
SKIFF_CONFIG=odroid/xu4,skiff/core make compile
```

You have to set `SKIFF_WORKSPACE` always, as this tells Skiff which workspace to use. However, Skiff will remember which config chain you used for the workspace, so you don't need to set it multiple times.

Next, type `make` to see the list of commands. Let's format the SD card at `/dev/sdb` for Skiff.

```
ODROID_SD=/dev/sdb make cmd/skiff/standard/format
```

This will format your SD card after some prompts with "are you sure" type messages. You might need to re-plug the SD card into your computer at this point.

Next, let's install everything:

```
ODROID_SD=/dev/sdb make cmd/odroid/u/install
```

You should now be able to plug the SD card into the board and boot.

If you change the config chain Skiff will automatically recognize this and re-configure. You only need to format the disk once. Later changes can be installed by running the install command alone.
