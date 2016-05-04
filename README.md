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
 - **RootFS Overlay**: optionally, the rootfs overlay drive is mounted and copied into the in-memory filesystem tree.
 - **Networking Init**: the networking subsystem is initialized and configured.
 - **Docker Init**: the Docker partition is mounted and the daemon launched.

Crew App Management
===================

Optionally, Skiff can use a minimal fork of Dokku named [Crew](http://github.com/paralin/crew) to build and manage Docker-based apps. Users can simply Git Push to the system to trigger a docker image build and deploy to the embedded environment. See the Crew repository for additional details.

User Environment Containers
===========================

Users can work within a familiar, traditional, persistent OS environment if desired. This is called the "core" user within Skiff. If this feature is enabled:

 - A **core** app is created within Crew.
 - Users push to the **core** app a "core environment" which is essentially a repository with a Dockerfile which describes the desired system environment. This can be Ubuntu, Alpine, Arch, or any other environment runnable under Docker.
 - SSH connections to the **core** user are dropped into the Docker container seamlessly.

This allows virtually any workflow to be migrated to Skiff with almost no effort.

Configuration Packages
======================

![](http://i.imgur.com/2nlUvvL.png)

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

Example: Odroid U3
==================

As an example, here's how to build SkiffOS for the ODROID U3.

Set the config setting `SKIFF_CONFIG` and the workspace `SKIFF_WORKSPACE` and kick off the build:

```
export SKIFF_WORKSPACE=tutorial
SKIFF_CONFIG=odroid/u make compile
```

You have to set `SKIFF_WORKSPACE` always, as this tells Skiff which workspace to use. However, Skiff will remember which config chain you used for the workspace, so you don't need to set it multiple times.

Next, type `make` to see the list of commands. Let's format the SD card at `/dev/sdb` for Skiff.

```
ODROID_SD=/dev/sdb make cmd/odroid/u/format
```

This will format your SD card after some prompts with "are you sure" type messages. You might need to re-plug the SD card into your computer at this point.

Next, let's install everything:

```
ODROID_SD=/dev/sdb make cmd/odroid/u/install
```

You should now be able to plug the SD card into the board and boot.

If you change the config chain Skiff will automatically recognize this and re-configure. You only need to format the disk once. Later changes can be installed by running the install command alone.
