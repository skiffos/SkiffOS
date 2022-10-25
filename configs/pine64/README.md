# Pine64 Configurations

This configuration package series configures Buildroot to produce a BSP image for the
PinePhone, PineBook, PineCube, and other Pine64 based devices.

There are specific configurations for each board, see "Board Compatibility."

References:

 - https://linux-sunxi.org/Pine_Pinebook
 - https://linux-sunxi.org/PinePhone
 - https://xnux.eu/devices/pine64-pinephone.html

# Board Compatibility

There are specific packages tuned to each model:

| **Board**       | **Config Package** | Notes          |
|-----------------|--------------------|----------------|
| [H64]           | [pine64/h64]       |                |
| [PineBook A64]  | [pine64/book_a64]  |                |
| [PineBook Pro]  | [pine64/book]      |                |
| [PinePhone]     | [pine64/phone]     |                |
| [PinePhone Pro] | [pine64/phone_pro] | ⚠ Experimental |
| [Rock64]        | [pine64/rock64]    |                |
| [RockPro64]     | [pine64/rockpro64] |                |

[H64]: https://www.pine64.org/pine-h64-ver-b/
[PineBook A64]: https://www.pine64.org/pinebook/
[PineBook Pro]: https://www.pine64.org/pinebook-pro/
[PinePhone]: https://www.pine64.org/pinephone/
[PinePhone Pro]: https://www.pine64.org/pinephonepro/
[Rock64]: https://www.pine64.org/rock64/
[RockPro64]: https://www.pine64.org/rockpro64/

[pine64/h64]: ./h64
[pine64/book]: ./book
[pine64/book_a64]: ./book_a64
[pine64/phone]: ./phone
[pine64/phone_pro]: ./phone_pro
[pine64/rock64]: ./rock64
[pine64/rockpro64]: ./rockpro64

# Flashing

Skiff is easiest installed to a SD card. A tool can be used to flash the OS to
the internal EMMC once booted to the SD card. The Pine64 system will boot from the
SD card if it is present and contains u-boot.

These commands require root and may need to be run with `sudo bash`.

```
# set SKIFF_WORKSPACE if you previously set it while compiling.
export SKIFF_WORKSPACE=myworkspace
export PINE64_SD=/dev/sdx # make sure this is correct - i.e. /dev/sdb
make cmd/pine64/common/format
make cmd/pine64/common/install
```

The "format" command creates the partition layout and installs u-boot. This only
needs to be run once. The "install" command copies the latest Image, dtb, boot
script, initramfs, and modules image to the boot and rootfs partitions. The root
system can be updated without touching the "persist" partition by running
"install" again whenever necessary.

