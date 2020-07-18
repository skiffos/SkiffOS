# NVIDIA upstream
FROM nvcr.io/nvidia/l4t-base:r32.4.3

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV container docker

# All packages
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  --no-install-recommends \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
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
  autotools-dev \
  cups \
  lightdm \
  xorg \
  xserver-xorg-input-all \
  locales \
  wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

# lightdm
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  --no-install-recommends \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
  lightdm xorg locales \
  lightdm-gtk-greeter \
  && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

RUN \
  adduser plasma \
  --no-create-home \
  --gecos "Unconfigured Workstation" \
  --shell /bin/bash \
  --disabled-password && \
  adduser plasma sudo && \
  adduser plasma root && \
  adduser plasma systemd-journal && \
  adduser plasma dialout && \
  adduser plasma plugdev && \
  mkdir -p /home/plasma/ && \
  chown plasma:plasma /home/plasma

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    echo "plasma	ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers && \
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

WORKDIR /home/plasma
ENTRYPOINT ["/lib/systemd/systemd"]
