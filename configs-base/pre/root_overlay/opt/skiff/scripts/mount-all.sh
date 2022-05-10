#!/bin/bash
set -a

BOOT_DEVICE="LABEL=boot"
PERSIST_DEVICE="LABEL=persist"
ROOTFS_DEVICE="LABEL=rootfs"
PERSIST_SUBDIR=/
PERSIST_MNT=/mnt/persist
BOOT_MNT=/mnt/boot
ROOTFS_MNT=/mnt/rootfs
SYSTEMD_CONFD=/etc/systemd/system
SKIP_MOUNT_FLAG=/etc/skip-skiff-mounts
SKIP_JOURNAL_FLAG=/etc/skip-skiff-journal-mounts
PRE_SCRIPTS_DIR=/opt/skiff/scripts/mount-all.pre.d
EXTRA_SCRIPTS_DIR=/opt/skiff/scripts/mount-all.d

# Run any additional pre setup scripts.
# We source these to allow overriding the above variables.
export SKIFF_RUN_INIT_ACTIONS="true"
for i in ${PRE_SCRIPTS_DIR}/*.sh ; do
    if [ -r $i ]; then
        source $i
    fi
done

# Ensure that / is mounted read-write if applicable
if [ -z "$DISABLE_ROOT_REMOUNT_RW" ]; then
    READ_ONLY_MOUNTS=$(awk '$4~/(^|,)ro($|,)/' /proc/mounts)
    if echo "${READ_ONLY_MOUNTS}" | grep -q "/ rootfs ro"; then
        echo "Remounting / read-write..."
        mount -o remount,rw / || true
    fi
fi

PERSIST_ROOT=$PERSIST_MNT
if [ -n "${PERSIST_SUBDIR}" ] && [[ "${PERSIST_SUBDIR}" != "/" ]]; then
    PERSIST_ROOT=${PERSIST_ROOT}/${PERSIST_SUBDIR}
fi

SKIFF_PERSIST=$PERSIST_ROOT/skiff
SKIFF_OVERLAYS=$PERSIST_ROOT/skiff-overlays
KEYS_PERSIST=$SKIFF_PERSIST/keys
SSH_PERSIST=$SKIFF_PERSIST/ssh
JOURNAL_PERSIST=$SKIFF_PERSIST/journal

SKIFF_RELEASE_FILE=/etc/skiff-release
if [ -f $SKIFF_RELEASE_FILE ]; then
    BUILD_DATE=$(cat /etc/skiff-release  | grep BUILD_DATE | cut -d\" -f2)
    BUILD_DATE_UTC=$(date --utc --date="$BUILD_DATE" +%s)
    CURRENT_DATE_UTC=$(date --utc +%s)
    if (( $BUILD_DATE_UTC > $CURRENT_DATE_UTC )); then
        echo "Build date of ${BUILD_DATE} is newer than internal clock of $(date). Bumping internal clock to build date."
        date -s "$BUILD_DATE" || true
    fi
fi

# Mount persist device, if applicable.
mkdir -p $SYSTEMD_CONFD $PERSIST_MNT
if [ -f $SKIP_MOUNT_FLAG ] || \
       mountpoint -q $PERSIST_MNT || \
       mount $PERSIST_MNT_FLAGS $PERSIST_DEVICE $PERSIST_MNT; then
    echo "Persist drive is at $PERSIST_MNT path $PERSIST_ROOT"
else
    echo "Unable to mount ${PERSIST_DEVICE}, continuing."
fi

# Create some dirs.
mkdir -p ${PERSIST_ROOT}/internal ${SKIFF_PERSIST}

# Setup journal persist.
mkdir -p /var/log/journal ${JOURNAL_PERSIST}
if [ ! -f $SKIP_JOURNAL_FLAG ] && ! mountpoint -q /var/log/journal ; then
    echo "Configuring systemd-journald to use $JOURNAL_PERSIST"
    mount --bind ${JOURNAL_PERSIST} /var/log/journal
    chmod 4755 /var/log/journal
    systemd-tmpfiles --create --prefix /var/log/journal || true
fi

# Setup ssh persist.
mkdir -p ${SSH_PERSIST}
if [ ! -f $SSH_PERSIST/sshd_config ]; then
    cp /etc/ssh/sshd_config $SSH_PERSIST/sshd_config
fi
if [ ! -f $SSH_PERSIST/ssh_config ]; then
    cp /etc/ssh/ssh_config $SSH_PERSIST/ssh_config
fi
if ! mountpoint -q /etc/ssh; then
    mount --bind $SSH_PERSIST /etc/ssh
fi


# mount /mnt/boot but only if MOUNT_BOOT_DEVICE is set.
if [ -n "$BOOT_DEVICE_MKDIR" ]; then
    mkdir -p ${BOOT_DEVICE} || echo "Unable to mkdir for boot rbind."
fi
mkdir -p ${BOOT_MNT}
if [ -f $SKIP_MOUNT_FLAG ] || \
       [ -z "$MOUNT_BOOT_DEVICE" ] || \
       mountpoint -q $BOOT_MNT || \
       mount $BOOT_MNT_FLAGS $BOOT_DEVICE $BOOT_MNT; then
    echo "Boot device is at ${BOOT_MNT}."
fi

# Mount rootfs.
if [ -n "$ROOTFS_DEVICE_MKDIR" ]; then
    mkdir -p ${ROOTFS_DEVICE} || echo "Unable to mkdir for rootfs rbind."
fi
mkdir -p $ROOTFS_MNT
if [ -f $SKIP_MOUNT_FLAG ] || \
       mountpoint -q $ROOTFS_MNT || \
       mount $ROOTFS_MNT_FLAGS $ROOTFS_DEVICE $ROOTFS_MNT; then
    echo "Rootfs drive is at ${ROOTFS_MNT}."
fi

# Build SSH keys list.
echo "Building SSH key list..."
mkdir -p $KEYS_PERSIST
echo "Put your SSH keys (*.pub) here." > $KEYS_PERSIST/readme
mkdir -p /root/.ssh
chmod 700 /root/.ssh
touch /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
mkdir -p /root/.ssh/tmp-keys
chmod 700 /root/.ssh/tmp-keys
if find ${KEYS_PERSIST} -name "*.pub" -mindepth 1 -maxdepth 1 | read; then
    cp $KEYS_PERSIST/*.pub /root/.ssh/tmp-keys/ 2>/dev/null || true
fi
if find /etc/skiff/authorized_keys -name "*.pub" -mindepth 1 -maxdepth 1 | read; then
    cp /etc/skiff/authorized_keys/*.pub /root/.ssh/tmp-keys/ 2>/dev/null || true
fi
if find /root/.ssh/tmp-keys -name "*.pub" -mindepth 1 -maxdepth 1 | read; then
    cat /root/.ssh/tmp-keys/*.pub > /root/.ssh/authorized_keys
else
    echo "No ssh keys present."
fi
rm -rf /root/.ssh/tmp-keys

# Setup network manager connections persist.
mkdir -p /etc/NetworkManager/system-connections
if ! mountpoint /etc/NetworkManager/system-connections ; then
    mkdir -p $PERSIST_ROOT/skiff/connections
    echo "# Place NetworkManager keyfile configs here." > $PERSIST_ROOT/skiff/connections/readme
    # chmod all files to 0600 or NetworkManager will not read them.
    chmod 600 ${PERSIST_ROOT}/skiff/connections/*
    mkdir -p /etc/NetworkManager/system-connections
    connections_workdir=${SKIFF_OVERLAYS}/nm_connections
    mkdir -p $connections_workdir
    mount -t overlay -o lowerdir=/etc/NetworkManager/system-connections,upperdir=${PERSIST_ROOT}/skiff/connections,workdir=$connections_workdir overlay /etc/NetworkManager/system-connections
fi
chmod 0755 /etc/NetworkManager
chmod 0644 /etc/NetworkManager/NetworkManager.conf
chmod -R 0600 /etc/NetworkManager/system-connections
chown -R root:root /etc/NetworkManager/system-connections

# Apply any etc overrides.
if [ -d $PERSIST_ROOT/skiff/etc ]; then
    rsync --exclude=/readme -rav $PERSIST_ROOT/skiff/etc/ /etc/
else
    mkdir -p $PERSIST_ROOT/skiff/etc/
fi
echo "Place etc overrides here." > $PERSIST_ROOT/skiff/etc/readme

# Apply hostname from persist partition.
if [ -f $PERSIST_ROOT/skiff/hostname ] && [ -n "$(cat ${PERSIST_ROOT}/skiff/hostname)" ]; then
    OHOSTNAME=$(cat /etc/hostname)
    if [ -z "$OHOSTNAME" ]; then
        OHOSTNAME=skiff-unknown
    fi
    NHOSTNAME=$(cat $PERSIST_ROOT/skiff/hostname)
    sed -i -e "s/$OHOSTNAME/$NHOSTNAME/g" /etc/hosts
    echo "$NHOSTNAME" > /etc/hostname

else
    hostname > $PERSIST_ROOT/skiff/hostname
    if [ "$(hostname)" == "" ]; then
        "skiff-unknown" > $PERSIST_ROOT/skiff/hostname
    fi
fi

hostname -F /etc/hostname # change transient hostname
systemctl daemon-reload

# Attempt to resize disk, if necessary.
# Note: this is an online resize, no re-mount required.
if [ -z "${DISABLE_RESIZE_PERSIST}" ]; then
    echo "Resizing ${PERSIST_MNT} if necessary..."
    embiggen-disk ${PERSIST_MNT} || echo "Failed to resize persist partition, continuing anyway."
fi

# Run any additional final setup scripts.
for i in ${EXTRA_SCRIPTS_DIR}/*.sh ; do
    if [ -r $i ]; then
        if ! $i ; then
            echo "Script at $i failed! Ignoring."
        fi
    fi
done

# Probe udev to make sure any new kernel modules are picked up.
systemctl daemon-reload
systemctl restart --no-block systemd-udev-trigger.service || true
