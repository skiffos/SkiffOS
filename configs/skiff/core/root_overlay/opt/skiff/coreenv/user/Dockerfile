# This is automatically changed to arm32v6/ubuntu (for example).
FROM ubuntu:bionic

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TERM xterm
ENV container docker

# Core packages
RUN apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y \
  openssh-client \
  vim \
  rsync \
  lsb-release \
  systemd \
  usbutils \
  sudo \
  curl \
  htop \
  nano \
  net-tools \
  apt-transport-https \
  software-properties-common \
  ca-certificates \
  gnupg-agent \
  unzip \
  wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# Create the user 'core' which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
  adduser core \
  --no-create-home \
  --gecos "Core" \
  --shell /bin/bash \
  --disabled-password && \
  adduser core sudo && \
  adduser core root && \
  adduser core dialout && \
  adduser core plugdev && \
  mkdir -p /home/core/ && \
  chown core:core /home/core && \
  echo "core    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*udev*' \
         -or -name '*freedesktop*' \
         -or -name '*persist-resize*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

ADD ./fstab /etc/fstab

WORKDIR /home/core
VOLUME ["/sys/fs/cgroup", "/tmp", "/run", "/run/lock"]
ENTRYPOINT ["/lib/systemd/systemd"]

