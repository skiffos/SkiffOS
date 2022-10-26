#!/bin/bash
set -eo pipefail

VOXL_PLATFORM_PATH=$1
if [ -z "$VOXL_PLATFORM_PATH" ] && [ -f /mnt/persist/voxl2_platform.tar.gz ]; then
   echo "Using voxl2_platform.tar.gz at /mnt/persist/voxl2_platform.tar.gz..."
   # If they didn't specify any but this is present, assume they meant to use it.
   VOXL_PLATFORM_PATH=/mnt/persist/voxl2_platform.tar.gz
fi

if [ -z "$VOXL_PLATFORM_PATH" ] || [ ! -f $VOXL_PLATFORM_PATH ]; then
    echo "usage: voxl2-import-core.sh voxl2_platform.tar.gz"
    echo "make sure voxl2_platform.tar.gz is in /mnt/persist"
    exit 1
fi

COREENV_PATH=/opt/skiff/coreenv/skiff-core-voxl2/
if [ ! -d ${COREENV_PATH} ]; then
    echo "Expected ${COREENV_PATH} but not found."
    echo "Please make sure you're running on SkiffOS for Voxl2 with skiff-core-voxl2."
    echo "You can try to force rebuild that package in SkiffOS: make br/skiff-core-voxl2-dirclean"
    echo "  make br/skiff-core-voxl2-dirclean"
    echo "  make compile"
    echo "... then re-flash SkiffOS.\n"
    echo "Otherwise open an issue: https://github.com/skiffos/skiffos/issues"
    exit 1
fi

WORK_DIR=/mnt/persist/import-core
WORK_MTPT=${WORK_DIR}/mtpt
mkdir -p ${WORK_DIR}
if mountpoint -q ${WORK_MTPT}; then
    echo "Unmounting old mtpt root..."
    umount --recursive ${WORK_MTPT}
fi
if [ -d ${WORK_DIR}/platform ]; then
    echo "Removing old extracted platform files..."
    rm -rf ${WORK_DIR}/platform
fi

ALPINE_IMAGE=docker.io/library/alpine:latest
if ! docker inspect ${ALPINE_IMAGE} >/dev/null 2>/dev/null; then
    echo "Pulling library/alpine:latest from Docker Hub..."
    docker pull ${ALPINE_IMAGE}
else
    echo "Docker image library/alpine:latest already exists..."
fi

WORK_CTR=tmp-android-tools
if docker inspect ${WORK_CTR} >/dev/null 2>/dev/null; then
    echo "Work container ${WORK_CTR} already exists, using it."
else
    echo "Running the container ${WORK_CTR}..."
    docker run --rm -d \
           --name="${WORK_CTR}" \
           -v ${WORK_DIR}:/work \
           docker.io/library/alpine:latest \
           sleep infinity
fi

STAGE2_CTR=tmp-voxl2-stage2
if docker inspect ${STAGE2_CTR} >/dev/null 2>/dev/null; then
    echo "Removing stage2 container..."
    docker rm -f ${STAGE2_CTR} || true
fi

function cleanup {
    if mountpoint -q ${WORK_MTPT}; then
        echo "Unmounting work mountpoint..."
        umount ${WORK_MTPT} || true
    fi
    if docker inspect ${WORK_CTR} >/dev/null 2>/dev/null; then
        echo "Removing work container..."
        docker rm -f ${WORK_CTR} || true
    fi
    if docker inspect ${STAGE2_CTR} >/dev/null 2>/dev/null; then
        echo "Removing stage2 container..."
        docker rm -f ${STAGE2_CTR} || true
    fi
}
trap cleanup EXIT

echo "Installing android-tools in the container..."
docker exec -it ${WORK_CTR} apk add android-tools

mkdir -p ${WORK_DIR}/platform
echo "Extracting $(basename ${VOXL_PLATFORM_PATH}) (this will take a minute)..."
tar -C ${WORK_DIR}/platform --strip-components=1 -xf ${VOXL_PLATFORM_PATH}

echo "Extracting sparse rootfs image (this will take a minute)..."
mkdir -p ${WORK_DIR}/extracted
docker exec -it ${WORK_CTR} \
       simg2img \
       /work/platform/system-image/qti-ubuntu-robotics-image-m0054-sysfs.ext4 \
       /work/extracted/sysfs.ext4

EXTRACTED_IMG=${WORK_DIR}/extracted/sysfs.ext4
echo "Extracted sysfs image to ${EXTRACTED_IMG}..."

echo "Mounting sysfs.ext4 to ${WORK_MTPT}"
mkdir -p ${WORK_MTPT}
mount -o loop ${EXTRACTED_IMG} ${WORK_MTPT}

DOCKER_IMG_BASE=skiffos/skiff-core-voxl2:base
echo "Importing the base docker image ${DOCKER_IMG_BASE} (this will take a while)..."
pushd ${WORK_MTPT}
tar -c . | docker import - ${DOCKER_IMG_BASE}
popd

echo "Unmounting work mountpoint..."
umount ${WORK_MTPT} || true

DOCKER_IMG_STAGE2=skiffos/skiff-core-voxl2:stage2
echo "Upgrading ${DOCKER_IMG_BASE} to ${DOCKER_IMG_STAGE2} (this will take a while)..."
pushd ${COREENV_PATH}
docker build -t ${DOCKER_IMG_STAGE2} -f Dockerfile.vendor .
popd

echo "Setting up temporary container to install voxl-sdk debs..."
docker run --rm -d \
       --entrypoint "/bin/bash" \
       --name="${STAGE2_CTR}" \
       -v ${WORK_DIR}:/mnt/work \
       ${DOCKER_IMG_STAGE2} \
       -c "sleep 1000000"

cat > ${WORK_DIR}/platform/voxl-sdk/install-debs.sh <<- EOM
#!/bin/bash
set -eo pipefail

echo "Disabling some audio modules..."
rm /etc/modules-load.d/audio_load.conf || true

echo "Scanning for dpkg packages..."
dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz

echo "Setting up apt source..."
echo "deb [trusted=yes] file:\$(pwd) ./" > /etc/apt/sources.list.d/local.list
apt-get update -o Dir::Etc::sourcelist="/etc/apt/sources.list.d/local.list" -o Dir::Etc::sourceparts="-" -o APT::Get::List-Cleanup="0"

# Disable systemctl as we don't have systemd running.
mv /bin/systemctl /bin/systemctl.bak
printf "#!/bin/bash\nexit 0\n" > /bin/systemctl
chmod +x /bin/systemctl

echo "Installing voxl-suite..."
apt-get install -y -o Dpkg::Options::="--force-overwrite" voxl-suite || true
apt-get install -f -y -o Dpkg::Options::="--force-overwrite" || true
apt-get install -y -o Dpkg::Options::="--force-overwrite" voxl-suite

mv /bin/systemctl.bak /bin/systemctl
EOM

echo "Running script to install the voxl-sdk debs (this will take a while)..."
docker exec -w /mnt/work/platform/voxl-sdk -it ${STAGE2_CTR} bash ./install-debs.sh

DOCKER_IMG_FINAL=skiffos/skiff-core-voxl2:latest
echo "Committing work container to ${DOCKER_IMG_FINAL} (this will take a moment)..."
docker commit ${STAGE2_CTR} ${DOCKER_IMG_FINAL}
docker rm -f ${STAGE2_CTR} || true

echo
echo "You will need to restart the core container to apply the changes:"
echo "    docker rm -f core"
echo "    systemctl restart skiff-core"
echo
echo "Then enter the core container user:"
echo "    su - core"
echo

# final cleanup, only if successful.
# otherwise we leave the files in place to review.
echo "Cleaning up temporary files (this will take a moment)..."
if [ -d ${WORK_DIR} ]; then
    rm -rf ${WORK_DIR} || true
fi
