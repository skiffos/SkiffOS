#!/bin/sh
# set -e

if [ ! -d "/opt/skiff" ]; then
  echo "Non-skiff system detected, bailing out!"
  exit 1
fi

INIT_ONCE=/run/skiff-inited

if [ -f $INIT_ONCE ]; then
  echo "$INIT_ONCE exists, bailing out."
  exit 0
fi

SYSTEMD_CONFD=/etc/systemd/system
DOCKER_CONFD=/etc/systemd/system/docker.service.d
PERSIST_MNT=/mnt/persist
ROOTFS_MNT=/mnt/rootfs

SKIFF_PERSIST=$PERSIST_MNT/skiff
KEYS_PERSIST=$SKIFF_PERSIST/keys
DOCKER_PERSIST=$SKIFF_PERSIST/docker
SSH_PERSIST=$SKIFF_PERSIST/ssh
JOURNAL_PERSIST=$SKIFF_PERSIST/journal

# Grab the default docker execstart
DOCKER_EXECSTART=$(cat /usr/lib/systemd/system/docker.service | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")

mkdir -p $SYSTEMD_CONFD
mkdir -p $DOCKER_CONFD
# echo "Mounting persist partition
mkdir -p $PERSIST_MNT
if mountpoint -q $PERSIST_MNT || mount LABEL=persist $PERSIST_MNT; then
  echo "Found and mounted persist drive to $PERSIST_MNT"
  mkdir -p $SKIFF_PERSIST
  mkdir -p $DOCKER_PERSIST
  mkdir -p $JOURNAL_PERSIST
  mkdir -p $SSH_PERSIST
  echo "Configuring Docker to use $DOCKER_PERSIST"
  DOCKER_EXECSTART+=" --graph=\"$DOCKER_PERSIST\""
  echo "Configuring systemd-journald to use $JOURNAL_PERSIST"
  systemctl stop systemd-journald || true
  if [ -d /var/log/journal ]; then
    rm -rf /var/log/journal || true
  fi
  ln -s $JOURNAL_PERSIST /var/log/journal
  chown -R root:systemd-journal /var/log/journal/
  systemctl start --no-block systemd-journald

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
if mountpoint -q $ROOTFS_MNT || mount -o ro LABEL=rootfs $ROOTFS_MNT; then
  echo "Found and mounted rootfs drive to $PERSIST_MNT"
else
  echo "Unable to find drive with label \"rootfs\"!"
fi

# cs: Allow docker to chose its own storage driver
# if modprobe aufs; then
#   echo "Successfully modprobed aufs, using it for docker."
#   DOCKER_EXECSTART+=" --storage-driver=aufs"
# fi

echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART" > $DOCKER_CONFD/execstart.conf

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

RESTART_NETWORKD=""
RESTART_WPA=""
if [ -d $PERSIST_MNT/skiff/wifi ]; then
  RESTART_WPA="yes"
  cp $PERSIST_MNT/skiff/wifi/*.conf /etc/wpa_supplicant/ || true
else
  mkdir -p $PERSIST_MNT/skiff/wifi
fi
echo "Place wpa-supplicant-wlan0.conf or similar here." > $PERSIST_MNT/skiff/wifi/readme

if [ -d $PERSIST_MNT/skiff/network ]; then
  RESTART_NETWORKD="yes"
  cp $PERSIST_MNT/skiff/network/*.network /etc/systemd/network/ || true
else
  mkdir -p $PERSIST_MNT/skiff/network
  cp /etc/systemd/network/* $PERSIST_MNT/skiff/network/
fi
echo "Place systemd-networkd config files here." > $PERSIST_MNT/skiff/network/readme

if [ -d $PERSIST_MNT/skiff/etc ]; then
  rsync -rav $PERSIST_MNT/skiff/etc/ /etc/
else
  mkdir -p $PERSIST_MNT/skiff/etc/
fi
echo "Place etc overrides here." > $PERSIST_MNT/skiff/etc/readme

if [ -f $PERSIST_MNT/skiff/hostname ]; then
  OHOSTNAME=$(cat /etc/hostname)
  NHOSTNAME=$(cat $PERSIST_MNT/skiff/hostname)
  sed -i -e "s/$OHOSTNAME/$NHOSTNAME/g" /etc/hosts
  echo "$NHOSTNAME" > /etc/hostname
  hostname $NHOSTNAME
else
  hostname > $PERSIST_MNT/skiff/hostname
fi

touch $INIT_ONCE
systemctl daemon-reload

if [ -n "$RESTART_WPA" ]; then
  systemctl restart --no-block 'wpa_supplicant@*'
fi

systemctl restart --no-block systemd-networkd || true
systemctl start --no-block multi-user.target || true
