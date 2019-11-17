# Intel Desktop

This configuration package contains (experimental) support for running SkiffOS
on a traditional desktop PC.

Additional kernel options are enabled to support a generic set of machines.
These modules should be disabled later to trim down the size of the OS.

The typical "boot" "rootfs" and "persist" partitions are reduced to a single
"skiffos" partition here.

## Installing on a MacBook

Setting up SkiffOS on a Macbook can be accomplished:

 1. Install "refind" with the "--alldrivers" option from the recovery mode.
 2. Use Recovery Mode and Disk Utility to create a SKIFFOS fat32 partition.
 3. Using mkfs.ext4, setup an ext4 filesystem on the partition.
 4. Label the filesystem "skiffos"
 5. Copy "bzImage" and "rootfs.cpio.gz" (renamed to initrd) to the partition.
 
That's it.

