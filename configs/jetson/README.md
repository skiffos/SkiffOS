# NVIDIA Linux for Tegra (L4T)

This configuration package configures Buildroot to produce a BSP image for the
Jetson TX1, TX2, AGX Xavier, or Nano boards.

There are specific configurations for each board, see "Board Compatibility."
 
Currently tested on the TX2 and Nano. Issue reports welcome.

## Board Compatibility

There are specific packages tuned to each model.

| **Board**       | **Config Package**    |
| --------------- | -----------------     |
| [Jetson Nano]   | [jetson/nano](./nano) |
| [Jetson TX2]    | [jetson/tx2](./tx2)   |

Jetson Xavier is compatible with the Jetson TX2 config.

[Jetson Nano]: https://developer.nvidia.com/embedded/jetson-nano-developer-kit
[Jetson TX2]: https://elinux.org/Jetson_TX2

## Flashing

See the readme for the individual board packages.

## Advantages vs. Jetpack

The current list of advantages to using this vs. NVIDIA Jetpack BSP:

 - Significantly simpler & more reliable OTA
   - read-only single-file host OS vs. read-write a/b partitions
   - can be upgraded with simple tools like rsync
   - does not require any complex boot-up process
 - [Upgraded kernel] from OE4T merged with more recent versions.
   - maintained by SkiffOS & OE4T developers
   - currently **4.9.306** vs Jetpack **4.9.253**
 - Full Jetpack compatibility: running in a container w/ Ubuntu.
 - Improved backup / restore UX with Docker CLI tools.
 
The skiff-core-linux4tegra package automatically applies the linux4tegra debs to
the latest Ubuntu bionic release, patching some files to skip hardware checks.

[Upgraded kernel]: https://github.com/skiffos/linux/tree/skiff-jetson-4.9.x

## Bootup Process

The TX2 and recent boards boot from the internal eMMC, at mmcblk0p1. The Jetson
Nano can boot to a SD card.

A "secure boot" process is used, with multiple bootloaders:

 - BootROM -> MB1 (TrustZone)
 - MB2/BPMP -> (Non-Trustzone)
 - Cboot (uses Little Kernel)
 - Uboot
 - Kernel
 
Uboot is flashed to the mmcblk0p1 emmc partition, and searches for the
"boot/extlinux/extlinux.conf" file in the persist partition.

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

# License Acknowledgment

The NVIDIA Linux4Tegra packages are licensed under the NVIDIA Customer Software
License. Skiff does not directly redistribute any parts of the toolkit, but will
download it as a Buildroot package from the NVIDIA servers as part of the build
process. The appropriate licenses can be viewed by triggering the Buildroot
"legal-info" build step. It is the responsibility of the end user / developer to be
aware of these terms and follow them accordingly.
