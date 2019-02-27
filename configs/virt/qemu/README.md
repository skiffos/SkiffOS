# Qemu Virtualization

This package allows Skiff to run in a virtualized qemu system.

```sh
$ SKIFF_CONFIG=virt/qemu make configure compile
$ make cmd/virt/qemu/run
```

You can press ctrl+a and then c (followed by return) to switch between the
serial output and the qemu monitor.
