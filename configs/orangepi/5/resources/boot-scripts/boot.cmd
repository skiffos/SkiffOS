setenv fdt_high ffffffff

setenv condev "console=ttyS2,1500000"
setenv verify 0
setenv bootlogo "false"

setenv bootargs "root=/dev/ram0 rootwait ro ${condev} earlyprintk no_console_suspend net.ifnames=0 root=UUID=${rootPartitionUUID} rootwait rootfstype=ext4 earlycon consoleblank=0 console=tty1"

# fdt_addr_r set by bootloader
# kernel_addr_r set by bootloader
setenv initramfs_addr_r "0x44000000"

load mmc 0 ${initramfs_addr_r} rootfs.cpio.uboot
load mmc 0 ${kernel_addr_r} zImage
load mmc 0 ${fdt_addr_r} rk3588s-orangepi-5.dtb

bootz ${kernel_addr_r} ${initramfs_addr_r} ${dtb_addr_r}


# U-Boot Parameters
setenv initrd_high "0xffffffff"
setenv fdt_high "0xffffffff"

# setenv silent 1
setenv condev "console=tty1 console=ttyAML0,115200n8"
setenv verify 0
setenv bootlogo "false"

setenv dtb_addr_r "0x1000000"
setenv kernel_addr_r "0x40008000"
setenv initramfs_addr_r "0x46000000"

# boot to memory for skiff
setenv bootmem "root=/dev/ram0 ro"

# max cpu frequency for little core, A55 in MHz unit
# setenv max_freq_a55 "2016"  # 2.016 Ghz
# setenv max_freq_a55 "1908"    # 1.908 GHz
setenv max_freq_a55 "1800"  # 1.8 Ghz
# setenv max_freq_a55 "1704"  # 1.704 GHz

# max cpu-cores
setenv maxcpus "4"

# Wake-On-Lan support (0=disable, 1=enable)
setenv enable_wol "0"

# Boot Args
setenv bootargs "coherent_pool=2M ${bootmem} ${condev} ${amlogic} no_console_suspend fsck.repair=yes net.ifnames=0 max_freq_a55=${max_freq_a55} maxcpus=${maxcpus} enable_wol=${enable_wol}"

load mmc ${devnum}:1 ${kernel_addr_r} Image
load mmc ${devnum}:1 ${initramfs_addr_r} rootfs.cpio.uboot
fatload mmc ${devnum}:1 ${dtb_addr_r} meson-sm1-odroid-hc4.dtb

fdt addr ${dtb_addr_r}

# boot
booti ${kernel_addr_r} ${initramfs_addr_r} ${dtb_addr_r}
