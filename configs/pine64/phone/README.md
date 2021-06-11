# Pine64 PinePhone

This configuration package `pine64/phone` compiles a Skiff base operating system
for the Pine64 PinePhone. Most of the other distributions are available as core
configurations.

References: 

 - https://linux-sunxi.org/PinePhone
 - https://wiki.pine64.org/index.php?title=PinePhone 
 - https://xnux.eu/devices/pine64-pinephone.html
 - https://xnux.eu/log/
 - https://xff.cz/kernels/
 - https://github.com/megous/linux/tree/orange-pi-5.13

## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=pine64/phone,core/pinephone_manjaro_kde
$ make configure                   # configure the system
$ make compile                     # build the system
```

The `core/pinephone_manjaro_kde` portion of SKIFF_CONFIG enables "Skiff Core"
with [Manjaro KDE for PinePhone].

Once the build is complete, it's time to flash the system. There are several
approaches, please see the "Flashing" section in the [common readme].

[common readme]: ../
[Manjaro KDE for PinePhone]: https://osdn.net/projects/manjaro-arm/storage/pinephone/plasma-mobile/dev/210102/

## Skiff Core: Available Variants

| **Distribution**           | **Config Package**            | **Notes**              |
| ---------------            | -----------------             | ---------------------- |
| PinePhone [KDE Neon]       | core/pinephone_neon           | Ubuntu-based KDE Neon  |
| PinePhone [Manjaro] KDE    | core/pinephone_manjaro_kde    | KDE Variant            |
| PinePhone [Manjaro] Lomiri | core/pinephone_manjaro_lomiri | Lomiri variant         |
| PinePhone [Manjaro] Phosh  | core/pinephone_manjaro_phosh  | Phosh variant          |
| PinePhone [UBTouch]        | core/pinephone_ubtouch        | Ubuntu Touch           |

[KDE Neon]: https://neon.kde.org/
[Manjaro]: https://manjaro.org/
[UBPorts]: https://ubuntu-touch.io/

## Ubuntu Touch

The [Ubuntu Touch] core `core/pinephone_ubtouch` adds additional kernel options
and support packages. Ubuntu Touch runs elements of Android which require
specific kernel features and other system-level customizations.

Unfortunately, this means the Ubuntu Touch image will not work unless SkiffOS
was compiled with the `core/pinephone_ubtouch` config enabled.

This is a work in progress at present and not all features work (yet).

[Ubuntu Touch]: https://devices.ubuntu-touch.io/device/pinephone

## Using Jumpdrive

Flashing using the micro "Jumpdrive" image is useful for recovery:

 1. Download the [Jumpdrive image]. 2. Flash&boot to a SD card: `xzcat jumpdrive.xz | dd of=/dev/sdx`
 3. Connect to PC over USB.
 4. The internal EMMC will appear as a new disk.

The disk now exists at, for example, `/dev/sdc`. Use the [flashing](../)
commands to flash SkiffOS to the EMMC.

[Jumpdrive image]: https://github.com/dremurrs-embedded/Jumpdrive/releases

## Upgrading Modem Firmware

The phone comes with a older version of the firmware pre-flashed to the modem.
To upgrade the modem firmware, follow the instructions on the [PinePhone
Firmware Wiki] page.

Reference:

 - [PinePhone Firmware Wiki]
 - https://github.com/Biktorgj/quectel_eg25_recovery
 - https://github.com/Biktorgj/qfirehose
 - https://git.sr.ht/~martijnbraam/pinephone-modemfw/

[PinePhone Firmware Wiki]: https://wiki.pine64.org/wiki/PineModems#Firmware_Recovery

## ModemManager

The SkiffOS configuration includes the relevant udev rules and firmware, but
does not include eg25-manager. ModemManager is included, and can be configured
to connect to a mobile network provider with the [corresponding APN]:

[corresponding APN]: https://wiki.pine64.org/wiki/PinePhone_APN_Settings

```
ssh root@pinephone
nmcli connection edit type gsm con-name "My Cellular Connection"
> set gsm.apn myapnhere
> print
> save
```

It should connect to the mobile network, you can use `mmcli` to check:

```
# power on modem, if not already powered
echo 1 > /sys/class/modem-power/modem-power/device/powered
# list modems
mmcli -L
# get modem status
mmcli --modem=0
```

## Known Issues

The following are known issues:

 - Crust/TF-A requires a musl or1k cross-compiler
   - Buildroot cannot build multiple toolchains in parallel
   - Skiff distributes pre-built u-boot binaries to fix this
   - Can re-compile the blobs from scratch with this repo:
   - https://github.com/skiffos/pinephone-crust-blobs
