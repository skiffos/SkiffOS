# XU4 EMMC Bootloader Flasher

This configuration is useful for flashing a up-to-date u-boot to EMMC images.

```
SKIFF_CONFIG=odroid/xu4mmcflash make configure compile
# Switch to root.
sudo bash
# Make sure you change sdX to the correct disk (i.e. sdb)
ODROID_SD=/dev/sdb make cmd/odroid/xu4mmcflash/format
```

After this, plug the SD into an XU3/XU4 and the target eMMC, and boot the system. The blue light will turn off when flashing is complete.
