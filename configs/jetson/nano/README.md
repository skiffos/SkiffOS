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

## Partition Layout

The required partition layout is somewhat complex and does not provide an
opportunity for separate "persist" and "boot" partitions as typically used by
other Skiff boards:

 - **APP**: at mmcblk0p1: contains the main system read-write filesystem.
 - **TBC**: TegraBoot CPU-side binary.
 - **RP1**: Bootloader DTB binary.
 - **EBT**: CBoot, the final boot stage CPU bootloader binary.
 - **WB0**: Warm boot binary.
 - **BPF**: SC7 entry firmware.
 - **BPF-DTB**: Reserved for future use by BPMP DTB binary; can't remove.
 - **FX**: Reserved for fuse bypass; removeable.
 - **TOS**: Required. Contains TOS binary.
 - **DTB**: Contains kernel DTB binary.
 - **LNX**: Contains U-Boot, which loads and launches the kernel.
 - **EKS**: Contains "the encrypted keys".
 - **BMP**: Contains BMP images for splash screen display during boot.
 - **RP4**: Contains XUSB module’s firmware file, making XUSB a true USB 3.0 host.
 - **GPT**: Contains secondary GPT of the sdcard device.

Unfortunately, the complex partition layout is unavoidable, but the Skiff
install and OTA scripts are careful to handle it properly.

## Advantages vs. Jetpack

The current list of advantages to using this vs. NVIDIA Jetpack BSP:

 - Significantly simpler & more reliable OTA
   - read-only single-file host OS vs. read-write a/b partitions
   - can be upgraded with simple tools like rsync
   - does not require any complex boot-up process
 - Upgraded kernel from OE4T merged with more recent versions.
   - maintained by SkiffOS & OE4T developers
 - Full Jetpack compatibility: running in a container w/ Ubuntu.
 - Improved backup / restore UX with Docker CLI tools.

The skiff-core-linux4tegra package automatically applies the linux4tegra debs to
the latest Ubuntu bionic release, patching some files to skip hardware checks.
