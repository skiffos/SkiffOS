#!/bin/sh
# set -eo pipefail

SYSTEMD_CONFD=/etc/systemd/system
DOCKER_SERVICE=/usr/lib/systemd/system/docker.service
DOCKER_CONFD=/etc/systemd/system/docker.service.d
PERSIST_MNT=/mnt/persist
ROOTFS_MNT=/mnt/rootfs
SKIP_MOUNT_FLAG=/etc/skip-skiff-mounts
SKIP_JOURNAL_FLAG=/etc/skip-skiff-journal-mounts
EXTRA_SCRIPTS_DIR=/opt/skiff/scripts/mount-all.d

SKIFF_PERSIST=$PERSIST_MNT/skiff
KEYS_PERSIST=$SKIFF_PERSIST/keys
DOCKER_PERSIST=$SKIFF_PERSIST/docker
SSH_PERSIST=$SKIFF_PERSIST/ssh
JOURNAL_PERSIST=$SKIFF_PERSIST/journal
SKIFF_RELEASE_FILE=/etc/skiff-release

# Fix for #52
if [ ! -d /run/dbus ]; then
    ln -fs /var/run/dbus/ /run/dbus
    systemctl restart --no-block systemd-hostnamed
fi

# Grab the default docker execstart
if [ -f $DOCKER_SERVICE ]; then
  DOCKER_EXECSTART=$(cat $DOCKER_SERVICE | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")
fi

if [ -f $SKIFF_RELEASE_FILE ]; then
    BUILD_DATE=$(cat /etc/skiff-release  | grep BUILD_DATE | cut -d\" -f2)
    BUILD_DATE_UTC=$(date --utc --date="$BUILD_DATE" +%s)
    CURRENT_DATE_UTC=$(date --utc +%s)
    if (( $BUILD_DATE_UTC > $CURRENT_DATE_UTC )); then
        echo "Build date of ${BUILD_DATE} is newer than internal clock of $(date). Bumping internal clock to build date."
        date -s "$BUILD_DATE" || true
    fi
fi

mkdir -p $SYSTEMD_CONFD
mkdir -p $DOCKER_CONFD
# echo "Mounting persist partition
mkdir -p $PERSIST_MNT
if [ -f $SKIP_MOUNT_FLAG ] || mountpoint -q $PERSIST_MNT || mount LABEL=persist $PERSIST_MNT; then
  echo "Persist drive is at $PERSIST_MNT"
  mkdir -p $PERSIST_MNT/internal
  mkdir -p $SKIFF_PERSIST
  mkdir -p $DOCKER_PERSIST
  mkdir -p $JOURNAL_PERSIST
  mkdir -p $SSH_PERSIST
  if [ -f $DOCKER_SERVICE ]; then
    echo "Configuring Docker to use $DOCKER_PERSIST"
    DOCKER_EXECSTART+=" --data-root=\"$DOCKER_PERSIST\""

    echo "Configuring Docker to use systemd-journald"
    DOCKER_EXECSTART+=" --log-driver=journald"
  fi

  if [ ! -f $SKIP_JOURNAL_FLAG ] && ! mountpoint -q /var/log/journal ; then
    echo "Configuring systemd-journald to use $JOURNAL_PERSIST"
    if [ -d /var/log/journal ]; then
     rm -rf /var/log/journal || true
    fi
    mkdir -p /var/log/journal
    mount --rbind ${JOURNAL_PERSIST} /var/log/journal
    chmod 4755 /var/log/journal
    systemd-tmpfiles --create --prefix /var/log/journal || true
  fi

  if [ ! -f $SSH_PERSIST/sshd_config ]; then
    cp /etc/ssh/sshd_config $SSH_PERSIST/sshd_config
  fi
  if [ ! -f $SSH_PERSIST/ssh_config ]; then
    cp /etc/ssh/ssh_config $SSH_PERSIST/ssh_config
  fi
  if ! mountpoint -q /etc/ssh; then
    mount --rbind $SSH_PERSIST /etc/ssh
  fi
  mkdir -p /root/persist
  if ! mountpoint -q /root/persist; then
    mount --rbind $PERSIST_MNT /root/persist || true
  fi
else
  echo "Unable to find drive with label \"persist\"! You will quickly run out of memory."
  mkdir -p /var/log/journal
fi

mkdir -p $ROOTFS_MNT
if [ -f $SKIP_MOUNT_FLAG ] || mountpoint -q $ROOTFS_MNT || mount -o ro LABEL=rootfs $ROOTFS_MNT; then
  echo "Rootfs drive at $PERSIST_MNT"
else
  echo "Unable to find drive with label \"rootfs\"!"
fi

if [ -f $DOCKER_SERVICE ]; then
  echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
  printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART" > $DOCKER_CONFD/execstart.conf
fi

echo "Building SSH key list..."
mkdir -p $KEYS_PERSIST
echo "Put your SSH keys (*.pub) here." > $KEYS_PERSIST/readme
mkdir -p /tmp/skiff_ssh_keys
mkdir -p /root/.ssh
touch /root/.ssh/authorized_keys
cp $KEYS_PERSIST/*.pub /tmp/skiff_ssh_keys 2>/dev/null || true
cp /etc/skiff/authorized_keys/*.pub /tmp/skiff_ssh_keys 2>/dev/null || true
if [ "$(ls -A /tmp/skiff_ssh_keys)" ]; then
  cat /tmp/skiff_ssh_keys/*.pub > /root/.ssh/authorized_keys
else
  echo "No ssh keys present."
fi
rm -rf /tmp/skiff_ssh_keys
chmod 700 /root/.ssh
chmod 600 /root/.ssh/authorized_keys

mkdir -p /etc/wpa_supplicant
overlay_workdir=${PERSIST_MNT}/skiff-overlays
if ! mountpoint /etc/wpa_supplicant ; then
  echo "Setting up overlay mount for wpa_supplicant..."
  mkdir -p $PERSIST_MNT/skiff/wifi
  echo "Place wpa-supplicant-wlan0.conf or similar here." > $PERSIST_MNT/skiff/wifi/readme
  wifi_workdir=${overlay_workdir}/wpa_supplicant
  mkdir -p $wifi_workdir
  mount -t overlay -o lowerdir=/etc/wpa_supplicant,upperdir=${PERSIST_MNT}/skiff/wifi,workdir=${wifi_workdir} overlay /etc/wpa_supplicant
fi

mkdir -p /etc/NetworkManager/system-connections
if ! mountpoint /etc/NetworkManager/system-connections ; then
  mkdir -p $PERSIST_MNT/skiff/connections
  echo "# Place NetworkManager keyfile configs here." > $PERSIST_MNT/skiff/connections/readme
  mkdir -p /etc/NetworkManager/system-connections
  connections_workdir=${overlay_workdir}/nm_connections
  mkdir -p $connections_workdir
  mount -t overlay -o lowerdir=/etc/NetworkManager/system-connections,upperdir=${PERSIST_MNT}/skiff/connections,workdir=$connections_workdir overlay /etc/NetworkManager/system-connections
fi
chmod 0755 /etc/NetworkManager
chmod 0644 /etc/NetworkManager/NetworkManager.conf
chmod -R 0600 /etc/NetworkManager/system-connections
chown -R root:root /etc/NetworkManager/system-connections

if [ -d $PERSIST_MNT/skiff/etc ]; then
  rsync -rav $PERSIST_MNT/skiff/etc/ /etc/
else
  mkdir -p $PERSIST_MNT/skiff/etc/
fi
echo "Place etc overrides here." > $PERSIST_MNT/skiff/etc/readme

if [ -f $PERSIST_MNT/skiff/hostname ] && [ -n "$(cat ${PERSIST_MNT}/skiff/hostname)" ]; then
  OHOSTNAME=$(cat /etc/hostname)
  if [ -z "$OHOSTNAME" ]; then
      OHOSTNAME=skiff-unknown
  fi
  NHOSTNAME=$(cat $PERSIST_MNT/skiff/hostname)
  sed -i -e "s/$OHOSTNAME/$NHOSTNAME/g" /etc/hosts
  echo "$NHOSTNAME" > /etc/hostname
  hostname -F /etc/hostname
else
  hostname > $PERSIST_MNT/skiff/hostname
  if [ "$(hostname)" == "" ]; then
      "skiff-unknown" > $PERSIST_MNT/skiff/hostname
  fi
fi

systemctl daemon-reload
hostname $(cat /etc/hostname)

# Run any additional final setup scripts.
for i in ${EXTRA_SCRIPTS_DIR}/*.sh ; do
    if [ -r $i ]; then
        if ! $i ; then
            echo "Script at $i failed! Ignoring."
        fi
    fi
done

# Probe udev to make sure any new kernel modules are picked up.
systemctl restart --no-block systemd-udev-trigger.service || true
