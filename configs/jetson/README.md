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

[Jetson Nano]: https://developer.nvidia.com/embedded/jetson-nano-developer-kit
[Jetson TX2]: https://elinux.org/Jetson_TX2

## Flashing

See the readme for the individual board package.

## Bootup Process

The TX2 and recent boards boot from the internal eMMC, at mmcblk0p1. The Jetson
Nano can boot to a SD card.

A "secure boot" process is used, with multiple bootloaders:

 - BootROM -> MB1 (TrustZone)
 - MB2/BPMP -> (Non-Trustzone)
 - Cboot (uses Little Kernel)
 - Uboot
 - Kernel
 
Uboot is flashed to the mmcblk0p1 emmc partition. Skiff compiles u-boot properly
for the boards, however it's not necessary to flash u-boot to begin using it.
There are scripts included designed to "upgrade" a factory-flashed TX2 Ubuntu
system to use Skiff, by overwriting the contents of the rootfs partition.

Cboot could be compiled from source, and the source is available from the
official sources, however, Skiff does not (yet) compile cboot.

## Core Image

The nvidia boards come with a Skiff Core configuration which installs the
JetPack debs inside the container. This brings in support for the NVIDIA JetPack
features, even inside the Core docker container, automatically.

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
"legal" build step. It is the responsibility of the end user / developer to be
aware of these terms and follow them accordingly.

