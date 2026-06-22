# Raspberry Pi

These configurations target the Raspberry Pi family of boards.

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pi/4,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will flash to a MicroSD card to boot. You will
need to `sudo bash` for this on most systems.

```sh
$ sudo bash             # switch to root
$ export PI_SD=/dev/sdz # make sure this is right! (usually sdb)
$ make cmd/pi/common/format  # tell skiff to format the device
$ make cmd/pi/common/install # tell skiff to install the os
```

You only need to run the `format` step once. It will create the partition table.
The `install` step will overwrite the current Skiff installation on the card,
taking care to not touch any persistent data (from the persist partition). It's
safe to upgrade Skiff independently from your persistent data.

## Board Compatibility

There are specific packages tuned to each Pi model.

| **Board**      | **Config Package** |
|----------------|--------------------|
| [Pi 0]         | pi/0               |
| [Pi 0 V2]      | pi/0v2             |
| [Pi 1]         | pi/1               |
| [Pi 2]         | pi/2               |
| [Pi 3]         | pi/3               |
| [Pi 3] - 64bit | pi/3x64            |
| [Pi 4]         | pi/4x64 or pi/4    |
| [Pi 4] - 32bit | pi/4x32            |
| [Pi 5]         | pi/5               |

[Pi 0]: https://www.raspberrypi.org/products/raspberry-pi-zero/
[Pi 0 V2]: https://www.raspberrypi.com/products/raspberry-pi-zero-2-w/
[Pi 1]: https://www.raspberrypi.org/products/raspberry-pi-1-model-b/
[Pi 2]: https://www.raspberrypi.org/products/raspberry-pi-2-model-b/
[Pi 3]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[Pi 4]: https://www.raspberrypi.org/products/raspberry-pi-4-model-b/
[Pi 5]: https://www.raspberrypi.org/products/raspberry-pi-5/

## Building an Image

It's possible to create a .img file instead of directly flashing a SD.

```sh
# must be root to use losetup
sudo bash
# set your skiff workspace
export SKIFF_WORKSPACE=default
# set the output path
export PI_IMAGE=./pi-image.img
# make the image
make cmd/pi/common/buildimage
```

The image can then be flashed to the target:

```
# change sdX to, for example, sdb
dd if=pi-image.img of=/dev/sdX status=progress oflag=sync
```

This is equivalent to using the format and install scripts.

The persist partition will be resized to fill the available space on first boot.

## USB Gadget Networking

Raspberry Pi USB gadget networking is opt-in. It only works on boards and USB
ports that support USB device/gadget mode, with a data-capable USB cable and a
host that accepts the gadget network interface. It is not guaranteed for every
Pi model, port, hub, or power-only cable.

The base kernel configuration includes gadget networking modules such as
`dwc2` and `g_ether`. Enable them from a custom Skiff config overlay instead of
editing generated output or the built image.

Create a custom config package that depends on your Pi config, then copy the
selected Pi boot files into it. For example:

```sh
mkdir -p my/pi-gadget/metadata my/pi-gadget/resources/rpi
printf 'pi/4,skiff/core\n' > my/pi-gadget/metadata/dependencies
cp configs/pi/common/resources/rpi/config.txt my/pi-gadget/resources/rpi/
cp configs/pi/common/resources/rpi/cmdline.txt my/pi-gadget/resources/rpi/
```

In `my/pi-gadget/resources/rpi/config.txt`, add:

```ini
dtoverlay=dwc2
```

In `my/pi-gadget/resources/rpi/cmdline.txt`, add `modules-load=dwc2,g_ether`
to the single existing line. Keep `cmdline.txt` as one line.

Use the custom package in `SKIFF_CONFIG`:

```sh
export SKIFF_CONFIG=my/pi-gadget
make configure
make compile
```

The examples below use host IP `10.0.0.1` and Pi device IP `10.0.0.3`.

### Host machine: NetworkManager sharing

To set up the host with NetworkManager:

 1. Create a new connection configuration in NetworkManager.
 2. Set the interface to the USB network interface, usually `usb0`.
 3. Set the IPv4 mode to Shared.
 4. Set the IPv4 address to `10.0.0.1`.
 5. Save and exit.

The equivalent host `nmconnection` file is:

```ini
[connection]
id=usbgadget
uuid=5349d6bb-6ee2-4c6d-8b70-4a9ebfa947b2
type=ethernet
interface-name=usb0

[ipv4]
address1=10.0.0.1/8
may-fail=false
method=shared
never-default=true

[ipv6]
method=disabled
```

### Host machine: manual iptables sharing

To set up the host without NetworkManager:

```sh
# add an IP address to usb0
ip addr add 10.0.0.1/24 dev usb0

# Enable forwarding internet traffic on behalf of the Pi.
# You can change OUTGOING to your outgoing interface, such as wlan0.
OUTGOING=$(ip route get 1.1.1.1 | cut -d" " -f5 | head -n1)
iptables -t nat -A POSTROUTING -s 10.0.0.3/32 -o ${OUTGOING} -j MASQUERADE
iptables -A FORWARD -s 10.0.0.3 -j ACCEPT
echo 1 > /proc/sys/net/ipv4/ip_forward
```

### Device IP address

Set the Pi's USB network address by adding a NetworkManager override to the
same custom config package:

`my/pi-gadget/overrides/root_overlay/etc/NetworkManager/system-connections/usb0.nmconnection`

Use the following contents:

```ini
[connection]
id=usb
uuid=004ae043-8866-4fa3-819a-8b5031c70c59
type=ethernet
interface-name=usb0

[ethernet]

[ipv4]
address1=10.0.0.3/8,10.0.0.1
dns=1.1.1.1;
method=manual

[ipv6]
addr-gen-mode=stable-privacy
method=disabled
```

Customize the Pi address by changing the first IP in `address1`. If you change
it, update the host address and iptables rules to match the same subnet.

## Note: config.txt

You can override the config.txt. Simply copy the "resources/rpi" directory from
the pi/common configuration into your own configuration package, for example:
"mypackage/resources/rpi/config.txt"

## Note: dtoverlay config.txt

Upstream adds `dtoverlay=miniuart-bt` to the config.txt, which should "fix
ttyAMA0 serial console.

## Note: 64 bit kernel

The pi/3x64 and pi/4x64 configurations use a 64 bit kernel with an alternate
config.txt, which specifies `arm_64bit` as required.

Raspbian does not use 64 bit yet and many of the video drivers don't work with
aarch64 yet.

According to the Gentoo wiki:

  The Raspberry Pi closed source VC4 driver is not available on 64-bit
  (ARM64/AARCH64) systems. The Raspberry Pi foundation has stated "we are not
  working on this, and are unlikely to do so in the near future". Using the open
  source vc4-fkms-v3d driver listed below instead is recommended.

References:

 - https://wiki.gentoo.org/wiki/Raspberry_Pi_VC4
 - https://github.com/raspberrypi/linux/issues/2315#issuecomment-383132350

## Overclocking

You will want to follow the upstream guidance on overclocking:

https://www.raspberrypi.org/documentation/configuration/config-txt/overclocking.md

Add the following snippet at the end of config.txt for a quick start. WARNING!
This will set a permanent bit on your Pi which will mark it as having been
overclocked. This will most-likely void the warranty.

```
over_voltage=4
force_turbo=1
max_usb_current=1
```

## Config.txt

Upstream docs: https://www.raspberrypi.com/documentation/computers/config_txt.html

The config.txt file supports conditional sections:

- `[pi1]`: Model A, Model B, Compute Module
- `[pi2]`: Model 2B (BCM2836- or BCM2837-based)
- `[pi3]`: Model 3B, Model 3B+, Model 3A+, Compute Module 3
- `[pi3+]`: Model 3A+, Model 3B+
- `[pi4]`: Model 4B
- `[pi5]`: Model 5
- `[pi0]`: Zero, Zero W, Zero WH
- `[pi0w]`: Zero W, Zero WH
