setenv fdt_high ffffffff

setenv condev "console=ttyS0,115200"
setenv bootargs "root=/dev/initrd rootwait ro ramdisk_size=100000 ${condev} earlyprintk no_console_suspend net.ifnames=0 elevator=noop"

# fdt_addr_r set by bootloader
# kernel_addr_r set by bootloader
setenv initramfs_addr_r "0x44000000"

fatload mmc 0 ${initramfs_addr_r} rootfs.cpio.uboot
fatload mmc 0 ${kernel_addr_r} zImage
fatload mmc 0 ${fdt_addr_r} sun8i-h2-plus-orangepi-zero.dtb

bootz ${kernel_addr_r} ${initramfs_addr_r} ${dtb_addr_r}

