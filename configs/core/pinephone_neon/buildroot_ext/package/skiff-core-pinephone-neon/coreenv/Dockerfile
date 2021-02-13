FROM skiffos/neon-pinephone-base:latest

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV container docker

RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y \
  -o "Dpkg::Options::=--force-confdef" \
  -o "Dpkg::Options::=--force-confnew" && \
  apt-get install -y \
  --no-install-recommends \
  -o "Dpkg::Options::=--force-confdef" \
  -o "Dpkg::Options::=--force-confnew" \
  build-essential \
  openssh-client \
  rsync \
  lsb-release \
  systemd \
  usbutils \
  sudo \
  curl \
  htop \
  git \
  vim \
  nano \
  net-tools \
  software-properties-common \
  unzip \
  locales \
  wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

RUN locale-gen "en_US.UTF-8"

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

RUN \
  adduser core \
  --no-create-home \
  --gecos "Unconfigured Workstation" \
  --shell /bin/bash \
  --disabled-password && \
  adduser core sudo && \
  adduser core root && \
  adduser core systemd-journal && \
  adduser core dialout && \
  adduser core plugdev && \
  mkdir -p /home/core/ && \
  chown core:core /home/core

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    echo "core  ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*NetworkManager*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
