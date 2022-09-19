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

To initialize the Voxl2 partition layout and other firmware files correctly,
first flash the latest BSP package from ModalAI:

 1. Navigate to https://developer.modalai.com/categories
 2. Select "Voxl 2 Platform Releases"
 3. Click "download" on [the entry] `voxl2_platform_1.3.1-0.8.tar.gz`
 4. Extract the file: `tar -zxf voxl2_platform_1.3.1-0.8.tar.gz`
 5. Enter the directory: `cd voxl2_platform_1.3.1-0.8`
 6. Unplug the voxl2 from power and USBC.
 7. Using something soft, hold down the SW1 button on the board.
 8. While holding the button, connect the power to the board.
 9. After about 5 seconds, release button SW1.
 10. Run the install script: `./install.sh`

[the entry]: https://developer.modalai.com/asset/eula-download/110

After following these steps, your system should be in factory-reset state.

To compile SkiffOS, set the comma-separated `SKIFF_CONFIG` variable:

```sh
$ export SKIFF_CONFIG=modalai/voxl2,skiff/core
$ make configure                   # configure the system
$ make compile                     # build the system
```

Once the build is complete, we will use Fastboot to flash the system to a
device. This will flash `apq8096-sysfs.ext4` to the `sysfs` partition and
`apq8096-boot.img` to the `boot` partition.

```sh
$ sudo bash
$ make cmd/modalai/voxl/flashusb  # tell skiff to use fastboot to flash
```

SkiffOS will use the existing `userdata` partition as its `persist` partition.
The flash script will not overwrite this partition, and can be used to update
the system later without clearing user data.

### Partitions

SkiffOS produces unsigned images for the `sysfs` and `boot` partitions, and uses
existing `aboot`, `cache`, `persist`, `userdata`, `recoveryfs` from the factory.

SkiffOS will use the `userdata` partition as its `persist` partition. It will
not overwrite this partition during the flash script, so the flash script can be
run multiple times without overwriting any container data.

To update the bootloader and other partitions, download & flash the system image
according to the [vendor docs], then run the SkiffOS flash script.

[vendor docs]: https://docs.modalai.com/downloads/

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
# Extract the modalai files.
gzip -c -d voxl2_platform_1.3.1-0.8.tar.gz | tar -xf-
cd ./voxl2_platform_1.3.1-0.8
cd ./system-image

# Decompress the sysfs image.
docker run --rm -v $(pwd):/data --workdir /data -it alpine:edge sh -c "apk add android-tools && simg2img qti-ubuntu-robotics-image-m0054-sysfs.ext4 sysfs.ext4"

# Mount the base system image.
mkdir -p mtpt
sudo mount -o loop -t ext4 ./sysfs.ext4 ./mtpt

# Import the base docker image.
cd ./mtpt
sudo tar -c . | docker import - skiffos/skiff-core-voxl2:base

# Unmount.
cd ..
sudo umount ./mtpt

# Use a dockerfile to adjust the image with some fixups.
cd /opt/skiff/coreenv/skiff-core-voxl2
docker build -f Dockerfile.minimize -t skiffos/skiff-core-voxl2:latest .

# Force skiff-core to load the new image.
# NOTE: this will delete your existing core container!
docker rm -f core
systemctl restart skiff-core

# You can delete the source files now.
# The Docker image is called skiffos/skiff-core-voxl2:latest
```

# License Acknowledgment

The ModelAI packages are provided under various licenses. Skiff does not
directly redistribute any parts of the toolkit, but will download them from the
upstream sources via Buildroot packages as part of the build process. Buildroot
produce a bundle of license files with "make br/legal-info". It is the
responsibility of the end user to follow all applicable licenses' terms.
