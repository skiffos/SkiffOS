# ModalAI Voxl2

This configuration package series configures Buildroot to produce a BSP image for the
[ModalAI Voxl2] model number `MDK-M0054`.

[ModalAI Voxl2]: https://docs.modalai.com/voxl-2/

References:

 - https://gitlab.com/voxl-public/support/documentation
 - https://gitlab.com/voxl-public/system-image-build/voxl-build
 - https://gitlab.com/voxl-public/system-image-build/meta-voxl2/-/tree/voxl2-14.1a
 - https://gitlab.com/voxl-public/system-image-build/meta-voxl2-bsp/-/tree/voxl2-14.1a
 - https://gitlab.com/voxl-public/system-image-build/qrb5165-kernel
 - http://voxl-packages.modalai.com/dev/
 - https://git.codelinaro.org/clo/la/kernel/msm-4.19 @ LU.UM.1.2.1.r1.3
 - https://git.codelinaro.org/clo/le/meta-qti-bsp/-/tree/LU.UM.1.2.1.r1-34500-QRB5165.0
 - https://git.codelinaro.org/clo/le/le/manifest at `LU.UM.1.2.1.r1-30500-QRB5165.0.xml`
 - http://releases.linaro.org/96boards/rb5/linaro/debian/21.08/
 
## Getting Started

Set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=modalai/voxl2,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will use Fastboot to flash the system to a
device. This will flash `apq8096-sysfs.ext4` to the `sysfs` partition and
`apq8096-boot.img` to the `boot` partition.

```sh
$ make cmd/modalai/voxl/flashusb  # tell skiff to use fastboot to flash
```

SkiffOS will use the existing `userdata` partition as its `persist` partition.
The flash script will not overwrite this partition, and can be used to update
the system later without clearing user data.

### OTA Update

To over-the-air update an existing system, use the push_image script:

```sh
$ ./scripts/push_image.bash root@my-ip-address
```

The SkiffOS upgrade (or downgrade) will take effect on next reboot.

### Boot Sequence and OTA

SkiffOS produces unsigned images for the `sysfs` and `boot` partitions, and uses
existing `aboot`, `cache`, `persist`, `userdata`, `recoveryfs` from the factory.

To enable remote OTA upgrades, `skiff-init-kexec` is used to execute the kernel
`Image` located on the `sysfs` partition:

 1. Kernel on the `boot` partition starts `/sbin/init` on `sysfs`.
 2. The `/sbin/init` file is symlinked to `/boot/skiff-init/skiff-init-kexec`.
 3. The `Image` is loaded from `/boot/Image` to memory.
 4. The new kernel is booted by calling `kexec`.
 5. The new kernel starts `/boot/skiff-init/skiff-init-squashfs`.
 6. `/boot/skiff-init/skiff-init-squashfs` mounts `/boot/rootfs.squashfs`.
 7. An overlay filesystem is mounted with a `tmpfs` to make `/` writable.
 8. The init script chroots and starts `/usr/lib/systemd/systemd`.

To update the bootloader and other partitions, download & flash the system image
according to the [vendor docs], then run the SkiffOS flash script.

[vendor docs]: https://docs.modalai.com/downloads/

SkiffOS will use the `userdata` partition as its `persist` partition. It will
not overwrite this partition during the flash script, so the flash script can be
run multiple times without overwriting any container data.

### Skiff Core: Default Ubuntu-based Image

The default configuration, `skiff-core-voxl2`, uses Ubuntu as the base image,
and installs the voxl2 platform debs from the [ModalAI packages server].

This is done with a Dockerfile on the target device on first boot. None of the
packages are downloaded during the SkiffOS build process.

[ModalAI packages server]: http://voxl-packages.modalai.com/dists/qrb5165/

### Skiff Core: Importing Vendor-provided Image

The vendor-provided system image can be imported to a skiff-core container. The
drivers provided in the container will then provide all proprietary features:

```sh
# Mount the base system image.
simg2img apq8096-sysfs.ext4 apq8096-sysfs.ext4.raw
mkdir -p mtpt
sudo mount -o loop -t ext4 ./apq8096-sysfs.ext4.raw ./mtpt

# Import the base docker image.
cd ./mtpt
sudo tar -c . | docker import - skiffos/skiff-core-voxl2:base

# Unmount.
cd ..
sudo umount ./mtpt

# Use the skiff-core-defconfig dockerfile to minimize the image.
wget -O Dockerfile https://raw.githubusercontent.com/skiffos/SkiffOS/master/configs/skiff/core/buildroot_ext/package/skiff-core-defconfig/coreenv/Dockerfile.minimize
docker build --build-arg "DISTRO=skiffos/skiff-core-voxl2:base" -t skiffos/skiff-core-voxl2:latest .
```

Edit `/mnt/persist/skiff/core/config.yaml` and replace the image name with
`skiffos/skiff-core-voxl2:latest`, then run `docker rm -f core` and then
`systemctl restart skiff-core` to create the new core container.

# License Acknowledgment

The ModelAI packages are provided under various licenses. Skiff does not
directly redistribute any parts of the toolkit, but will download them from the
upstream sources via Buildroot packages as part of the build process. Buildroot
produce a bundle of license files with "make br/legal-info". It is the
responsibility of the end user to follow all applicable licenses' terms.
