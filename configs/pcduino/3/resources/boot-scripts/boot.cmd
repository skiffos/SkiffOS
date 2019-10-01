setenv bootargs ramdisk_size=100000

fatload mmc 0 "$ramdisk_addr_r" rootfs.cpio.uboot
fatload mmc 0 "$kernel_addr_r" zImage
fatload mmc 0 "$fdt_addr_r" "$fdtfile"

bootz "$kernel_addr_r" "$ramdisk_addr_r" "$fdt_addr_r"
