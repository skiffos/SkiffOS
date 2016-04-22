# SkiffOS

![](http://i.imgur.com/oZtPvSc.png)

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
