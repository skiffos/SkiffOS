# Pine64 PineCube

This configuration package `pine64/cube` compiles a Skiff base operating system
for the Pine64 PineCube, an Allwinner S3 (Cortex-A7) camera board with 128 MB of
RAM. It builds the mainline kernel with `sunxi_defconfig` and mainline U-Boot
with the `pinecube` defconfig, and boots through extlinux.

References:

 - https://wiki.pine64.org/wiki/PineCube

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/cube
$ make configure                   # configure the system
$ make compile                     # build the system
```

The board has 128 MB of RAM, so leave out `skiff/core` and Docker. The `lite`
fragment drops ModemManager and smartmontools, and a sysctl keeps 4 MB free for
the atomic allocations the Ethernet driver makes when `eth0` opens.

## Flashing

These commands require root and may need to be run with `sudo bash`.

```sh
export PINE64_SD=/dev/sdx # make sure this is correct - i.e. /dev/sdb
make cmd/pine64/cube/format       # partition the card and write U-Boot
make cmd/pine64/cube/install      # copy the kernel, dtb, rootfs and modules
```

Or build a card image with `PINE64_IMAGE=./pinecube.img make
cmd/pine64/cube/buildimage` and write it with `dd`.

The serial console is on UART2 at 115200 8N1.

## Hardware

 - Camera: OV5640 on the CSI interface (`ov5640` and `sun6i-csi` modules).
 - Ethernet: the S3's internal PHY.
 - WiFi: RTL8189ES, built out of tree by the `rtl8189es` package.
 - Mainline Linux has no hardware H.264 encoder for the S3, so the camera
   delivers raw or MJPEG frames.
