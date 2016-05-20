#!/bin/sh
set -e

if [ ! -d "/opt/skiff" ]; then
  echo "Non-skiff system detected, bailing out!"
  exit 1
fi

INIT_ONCE=/run/skiff-inited

if [ -f $INIT_ONCE ]; then
  echo "$INIT_ONCE exists, bailing out."
  exit 0
fi

DRIVES=$(blkid)
SYSTEMD_CONFD=/etc/systemd/system
DOCKER_CONFD=/etc/systemd/system/docker.service.d
PERSIST_MNT=/mnt/persist
PERSIST_DRIVE=$(echo "$DRIVES" | grep "LABEL=\"persist\"")
SKIFF_PERSIST=$PERSIST_MNT/skiff
KEYS_PERSIST=$SKIFF_PERSIST/keys
DOCKER_PERSIST=$SKIFF_PERSIST/docker
JOURNAL_PERSIST=$SKIFF_PERSIST/journal

# Grab the default docker execstart
DOCKER_EXECSTART=$(cat /usr/lib/systemd/system/docker.service | grep '^ExecStart=.*$' | sed -e "s/ExecStart=//")

mkdir -p $SYSTEMD_CONFD
mkdir -p $DOCKER_CONFD
# echo "Mounting persist partition
if [ -n "$PERSIST_DRIVE" ]; then
  if ! mountpoint -q $PERSIST_MNT; then
    PERSIST_DEV=$(echo "$PERSIST_DRIVE" | cut -d: -f1)
    echo "Found persist drive $PERSIST_DEV, mounting to $PERSIST_MNT"
    mkdir -p $PERSIST_MNT
    mount $PERSIST_DEV $PERSIST_MNT
    mkdir -p $SKIFF_PERSIST
    mkdir -p $DOCKER_PERSIST
    mkdir -p $JOURNAL_PERSIST
    echo "Configuring Docker to use $DOCKER_PERSIST"
    DOCKER_EXECSTART+=" --graph=\"$DOCKER_PERSIST\""
    echo "Configuring systemd-journald to use $JOURNAL_PERSIST"
    if [ -d /var/log/journal ]; then
      rm -rf /var/log/journal || true
    fi
    ln -s $JOURNAL_PERSIST /var/log/journal
    chown -R root:systemd-journal /var/log/journal/
  fi
else
  echo "Unable to find drive with label \"persist\"! You will quickly run out of memory."
  mkdir -p /var/log/journal
fi

if modprobe aufs; then
  echo "Successfully modprobed aufs, using it for docker."
  DOCKER_EXECSTART+=" --storage-driver=aufs"
fi

echo "Configuring Docker to start with '$DOCKER_EXECSTART'"
printf "[Service]\nExecStart=\nExecStart=$DOCKER_EXECSTART" > $DOCKER_CONFD/execstart.conf

echo "Building SSH key list..."
mkdir -p $KEYS_PERSIST
echo "Put your SSH keys (*.pub) here." > $KEYS_PERSIST/PUT_KEYS_HERE
mkdir -p /tmp/skiff_ssh_keys
mkdir -p /root/.ssh
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

if [ -d $PERSIST_MNT/skiff/wifi ]; then
  cp $PERSIST_MNT/skiff/wifi/*.conf /etc/wpa_supplicant/ || true
fi

if [ -d $PERSIST_MNT/skiff/network ]; then
  cp $PERSIST_MNT/skiff/network/*.network /etc/systemd/network/ || true
fi

touch $INIT_ONCE
systemctl daemon-reload
systemctl restart systemd-journald
