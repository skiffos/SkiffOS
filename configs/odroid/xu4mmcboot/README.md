# XU4 EMMC Booter

This configuration is useful for building an SD card that can boot an EMMC without a working bootloader.

```
SKIFF_CONFIG=odroid/xu4,odroid/xu4mmcflash make configure compile
# Switch to root.
sudo bash
# Make sure you change sdX to the correct disk (i.e. sdb)
ODROID_SD=/dev/sdb make cmd/odroid/xu4mmcboot/format
```

After this, plug the SD into an XU3/XU4 and the target eMMC, and boot the system. The blue light will turn off when flashing is complete.
