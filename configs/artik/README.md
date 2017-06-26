# Artik Boards

This document contains notes about the Artik series of boards and their support in Skiff.

## Output Images

There are two supported ways of flashing Skiff to a device:

 1. Intermediate flashing SD card.
 2. Fastboot flash
 
## Fastboot Flash

Build the image:

```bash
SKIFF_CONFIG=artik/710 make configure compile
```

Then install it with fastboot:

```bash
make cmd/artik/710/fastboot
```

You will be guided through the process in the output of the command.

## First Boot

The first boot the system has to do two things that take quite a while:

 - Resize the persist partition
