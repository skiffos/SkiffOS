# Apple Macbook (Intel)

This package supports the Intel Macbook Pros.

It is tested on the MacBookPro 12,1 but should work with any amd64.

## Setup

The configuration / setup process is a work in progress:

1. Use Recovery Mode and Disk Utility to create an EFI partition and a
   SKIFFOS partition.
2. Format the EFI partition as FAT32.
3. Format the SKIFFOS partition as ext4 and label it `SKIFFOS`.
4. In a root shell, set `INTEL_DESKTOP_PARTITION` to the SKIFFOS partition,
   such as `/dev/sdb3`.
5. Use `make cmd/intel/desktop/install` to install.

The format command installs Clover on the EFI partition. The installer keeps
matching kernel and squashfs files in `/boot/current` and `/boot/previous`.
Clover offers the current slot and the previous slot as recovery.
