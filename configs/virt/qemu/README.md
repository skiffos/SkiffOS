# Qemu Virtualization

This package allows Skiff to run in a virtualized qemu system.

```sh
$ SKIFF_CONFIG=virt/qemu make configure compile
$ make cmd/virt/qemu/run
```

You can press ctrl+a and then c (followed by return) to switch between the
serial output and the qemu monitor. The "stop" command in the monitor shell will
stop emulation.

Log in as "root" for the default Skiff setup.

The full qemu command is:

```
qemu-system-x86_64 \
  -nographic -serial mon:stdio \
	-kernel bzImage \
	-initrd rootfs.cpio.lz4 -m size=512 \
	-append "nokaslr norandmaps console=ttyS0 console=tty root=/dev/ram0" \
	-drive file=${ROOTFS_DISK},if=virtio \
	-net nic,model=virtio \
	-net user 
	# For compat: -cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic
```

Within the `workspaces/myworkspace/images` directory.

Note: the default qemu configuration is adjusted slightly such that "root" will
sign in without a password prompt on the serial console.

