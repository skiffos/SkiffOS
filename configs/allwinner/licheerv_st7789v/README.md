# Sipeed LicheeRV Dock with ST7789V SPI TFT display.

This is a utility package to add patches to the LicheeRV Dock kernel to enable
using an ST7789V SPI TFT display.

Read the main [LicheeRV docs](../licheerv) for more information.

## Example

![Demo](https://i.imgur.com/rymQqgH.jpg)

```
export SKIFF_CONFIG=allwinner/licheerv_st7789v,util/rootlogin
make configure compile

# install
sudo bash
export ALLWINNER_SD=/dev/sdd
make cmd/allwinner/d1/format
make cmd/allwinner/d1/install

# on the device:
# serial debug
screen /dev/ttyUSB0 115200
# login as root
fb-test
# test image will be displayed
# or to show a image:
fbv sample.jpg
# press n to rotate 90*
```

The sample.jpg image is available at resources/images/sample-500x500.jpg.
