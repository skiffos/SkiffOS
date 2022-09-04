# NVIDIA Jetson AGX

This package targets the NVIDIA Jetson AGX Orin and Xavier series of boards.

Reference:

 - https://nv-tegra.nvidia.com/r/gitweb?p=linux-5.10.git;a=summary
 - https://nv-tegra.nvidia.com/r/linux-5.10.git
 - https://nv-tegra.nvidia.com/r/linux-nvidia.git
 - https://nv-tegra.nvidia.com/r/gitweb?p=linux-nvidia.git

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=jetson/agx
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, it's time to flash the system via USB. You will need
to switch to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
# follow the "Flashing" process described below.
```

Note: the "flashusb" recovery mode flashing approach will overwrite the
"persist" data as well. This is a limitation of the flashing process and
partition layout on the internal emmc.

## Flashing via USB

Flashing to the internal eMMC is done by booting to the official recovery mode,
and flashing the system from there.

The recovery mode of the Jetson AGX is used to flash SkiffOS. Entering recovery:

 - Start with the machine powered off + fully unplugged.
 - Connect a micro-USB cable from the host PC to the target board.
 - Connect the board to power.
 - Hold down the Force Recovery button.
 - Hold down the Power button.
 - Release the Power button.
 - Wait a moment.
 - Release the Force Recovery button.

SkiffOS uses the Tegra for Linux package to flash over USB.

To flash over USB:

```
export SKIFF_NVIDIA_USB_FLASH=confirm
make cmd/jetson/agx/flashusb
```

This will run the `flash.sh` script from L4T, and will setup the kernel, u-boot,
persist + boot-up partition mmcblk0p1.

After Skiff is installed, the system can be OTA updated by using the
`scripts/push_image.sh` script:

```
./scripts/push_image.sh root@myjetsonagx
```

The flash script will overwrite the entire persist partition. This is due to a
limitation in the flashing process: the jetson internal EMMC partition layout
has a single "app" partition. The recovery mode is used to flash a ext4 image to
that partition containing the system files. Partial flashing would need separate
partitions to work correctly. Please use the `push_image.sh` script to update.
