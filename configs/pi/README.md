# Raspberry Pi

These configurations target the Raspberry Pi family of boards.

## Board Compatibility

There are specific packages tuned to each Pi model. However, certain packages
are forwards or backwards compatible.

| **Board**       | **Config Package** |
| --------------- | -----------------  |
| [Pi 0]          | pi/0               |
| [Pi 1]          | pi/1 or pi/3       |
| [Pi 2]          | pi/3               |
| [Pi 3]          | pi/3 or pi/4       |
| [Pi 4]          | pi/4 or pi/3       |

[Pi 4]: https://www.raspberrypi.org/products/raspberry-pi-4-model-b/
[Pi 3]: https://www.raspberrypi.org/products/raspberry-pi-3-model-b/
[Pi 2]: https://www.raspberrypi.org/products/raspberry-pi-2-model-b/
[Pi 1]: https://www.raspberrypi.org/products/raspberry-pi-1-model-b/
[Pi 0]: https://www.raspberrypi.org/products/raspberry-pi-zero/

## Note: config.txt

You can override the config.txt. Simply copy the "resources/rpi" directory from
the pi/common configuration into your own configuration package, for example:
"mypackage/resources/rpi/config.txt"

## Note: dtoverlay config.txt

Upstream adds `dtoverlay=miniuart-bt` to the config.txt, which should "fix
ttyAMA0 serial console.

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
