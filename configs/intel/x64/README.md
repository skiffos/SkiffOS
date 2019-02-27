# X86_64 Build

This configuration targets x86_64 CPUs.

## Qemu

Minimal booting example:

```bash
qemu-system-x86_64 \
	-kernel bzImage \
	-append "console=tty root=/dev/ram0" \
	-initrd rootfs.cpio.gz -m size=512
```

Some fancy bells and whistles:

```bash
qemu-system-x86_64 \
	-kernel bzImage \
	-initrd rootfs.cpio.gz -m size=512 \
	-append "nokaslr norandmaps console=tty root=/dev/ram0" \
	-net nic,model=virtio \
	-net user \
	-cpu qemu64,+ssse3,+sse4.1,+sse4.2,+x2apic
```

There's a script that does this for you. It sets up a root disk correctly.

```bash
make cmd/intel/x64/qemu
```

