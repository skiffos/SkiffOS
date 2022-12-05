# Configuring

SkiffOS is designed to be easy to configure with bundles called "packages" which
contain options for the system components. For example:

`SKIFF_CONFIG=pi/4,apps/docker`

... compiles a Raspberry Pi 4 image with Docker installed & running.

You can [add out-of-tree SkiffOS configuration packages] with custom
configuration packages as well.

[add out-of-tree SkiffOS configuration packages]: https://github.com/skiffos/skiff-ext-example/blob/b2ec903/configs/mycustom/device/kernel/wireguard#L1

There are two major components that you usually will want to configure:

 - Kernel config: usually enabling additional modules or options.
 - Buildroot packages: external kernel modules or userspace apps

This is a brief guide on these.

## Kernel

To enable a new kernel module:

 1. Configure SkiffOS with `make configure` (see the README).
 2. Open the kernel config editor with `make br/linux-menuconfig`
 3. Find the option(s) or module(s) you want to enable.
 4. Add the configuration options to a file for SkiffOS.

Kernel configuration variables always have a `CONFIG_` prefix.

Examples:

```
# Enable rtl8188eu kernel module.
CONFIG_RTL8188EU=m

# Enable memory cgroups.
CONFIG_MEMCG=y

# Disable MEDIA_TUNER.
# CONFIG_MEDIA_TUNER is not set
```

The `# CONFIG_FOO is not set` syntax unsets the configuration option.

Other lines with a `#` prefix are comments.

The configuration files can be written to any of these locations:

 - Inside a configuration package, in the `kernel` sub-directory.
 - Inside the "overrides" configuration package at `./overrides/kernel`.
 - Inside the workspace-specific overrides at `./overrides/workspaces/default/kernel`.

Keep in mind you can [add out-of-tree SkiffOS configuration packages].

[add out-of-tree SkiffOS configuration packages]: https://github.com/skiffos/skiff-ext-example/blob/b2ec903/configs/mycustom/device/kernel/wireguard#L1

## Buildroot package

To enable a buildroot package:

 1. Configure SkiffOS with `make configure` (see the README).
 2. Open the editor with `make menuconfig` or `make xconfig`
 3. Find the package you want to enable.
 4. Add the configuration options to a file in SkiffOS.

Buildroot configuration variables usually have a `BR2_` prefix.

Examples:

```
# Enable linux firmware for rtl8821cu.
BR2_PACKAGE_LINUX_FIRMWARE_RTL_RTW88=y
BR2_PACKAGE_LINUX_FIRMWARE_RTL_88XX_BT=y

# Enable rtl8821cu out-of-tree kernel module.
BR2_PACKAGE_RTL8821CU=y

# Unset installing modem-manager.
# BR2_PACKAGE_MODEM_MANAGER is not set
```

The `# CONFIG_FOO is not set` syntax unsets the configuration option.

Other lines with a `#` prefix are comments.

The configuration files can be written to any of these locations:

 - Inside a configuration package, in the `buildroot` sub-directory.
 - Inside the "overrides" configuration package at `./overrides/buildroot`.
 - Inside the workspace-specific overrides at `./overrides/workspaces/default/buildroot`.

Keep in mind you can [add out-of-tree SkiffOS configuration packages].

[add out-of-tree SkiffOS configuration packages]: https://github.com/skiffos/skiff-ext-example/blob/b2ec903/configs/mycustom/device/buildroot/nm#L2

## Firmware

Follow the steps to configure Buildroot above. Select the firmware for your device.
