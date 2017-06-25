# Artik Boards

This document contains notes about the Artik series of boards and their support in Skiff.

## Output Images

There are two supported ways of flashing Skiff to a device:

 1. Intermediate flashing SD card.
 2. Fastboot flash
 
## Fastboot Flash

```sh
sudo fastboot flash partmap partmap-emmc.txt
sudo fastboot flash 2ndboot bl1-emmcboot.img
sudo fastboot flash fip-loader fip-loader-emmc.img
sudo fastboot flash fip-secure fip-secure.img
sudo fastboot flash fip-nonsecure fip-nonsecure.img
sudo fastboot flash env params_emmc.bin
sudo fastboot flash boot boot.img
sudo fastboot flash modules modules.img
```
