# USB Armory

These configurations target the [USB Armory] family of boards.

Reference:

 - https://github.com/f-secure-foundry/usbarmory/wiki
 - https://github.com/f-secure-foundry/usbarmory/tree/master/software/buildroot
 - https://github.com/sakaki-/gentoo-on-armory

[USB Armory]: https://github.com/f-secure-foundry/usbarmory

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=usbarmory/mk2,core/alpine,util/rootlogin
$ make configure                   # configure the system
$ make compile                     # build the system
```

The `core/alpine` portion of SKIFF_CONFIG enables core with Alpine Linux.

The `util/rootlogin` config enables root login w/o a password over serial.

Once the build is complete, it's time to flash the system to a SD card.

```sh
$ sudo bash                         # requires root in most cases
$ export USBARMORY_SD=/dev/sdX      # set to SD card path
$ make cmd/usbarmory/common/format  # create partitions
$ make cmd/usbarmory/common/install # copy system files
```

Future updates can be done with `install`, skipping the `format` step.

Plug the SD card into the device. Make sure the boot select switch is pushed
towards the microSD card slot, to select SD boot (instead of emmc).

## Board Compatibility

There are specific packages tuned to each revision:

| **Board**       | **Config Package** |
| --------------- | -----------------  |
| [Mark 2]        | usbarmory/mk2      |

[Mark 2]: https://inversepath.com/usbarmory.html

## Work in Progress

The following features are not yet complete:

 - Interlock
 - caam-keyblob
 - mxc-scc2
 - mxc-dcp
 - qubes-app-linux-split-gpg
 - dhcp server on usb0
 
Note: the ethernet / USB I/O is quite slow and may require some patience.

## Squashfs Boot

The USB Armory is a memory-constrained machine and as such uses the "squashfs"
boot mechanism (similar to the Jetson TX2). This mounts a squashfs from the boot
media rather than load the entire OS into RAM.

## Ethernet over USB

The default configuration enables g_ether USB ethernet gadget support.

To setup on the "host" machine:

```sh 
$ ip addr add 10.0.0.2/24 dev usb0

# some systems may require adjusting iptables:
$ iptables -t nat -A POSTROUTING -s 10.0.0.1/32 -o wlan0 -j MASQUERADE
$ iptables -A FORWARD -s 10.0.0.1 -j ACCEPT
$ echo 1 > /proc/sys/net/ipv4/ip_forward
```

## Serial over USB

Enable the `util/rootlogin` configuration package to enable root login.

The default configuration will enable both USB ethernet and serial. The serial
device should appear at `/dev/ttyACM0` on the host machine.

Access it with `screen /dev/ttyACM0 115200`.

Note that on first start, the device will be busy performing first setup, so the
serial shell might not appear for 1-2 minutes. Any internet usage will also
saturate the I/O and make the terminal lag.
