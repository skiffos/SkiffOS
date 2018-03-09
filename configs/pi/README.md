# Raspberry Pi

These configurations target the Raspberry Pi family of boards.

## Note: config.txt

You can override the config.txt. Simply copy the "resources/rpi" directory from the pi/common configuration into your own configuration package, for example: "mypackage/resources/rpi/config.txt"

## Note: start_x Option

To enable the camera, the Raspberry Pi guide says to enable "start_x."

Don't do this. Instead, add the pi/camera package.
