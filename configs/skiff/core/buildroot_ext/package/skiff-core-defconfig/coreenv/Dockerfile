ARG DISTRO
FROM ${DISTRO:-debian:sid} as stage1

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    container=docker

# Download apt cache
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get update

# Minimal desktop environment.
RUN \
    apt-get dist-upgrade -y && \
    apt-get install -y  \
    --no-install-recommends \
    --ignore-missing \
    -o "Dpkg::Options::=--force-confdef"  \
    -o "Dpkg::Options::=--force-confnew"  \
    autotools-dev \
    build-essential \
    chromium \
    cups \
    curl \
    git \
    htop \
    less \
    lightdm \
    locales \
    lsb-release \
    mesa-utils \
    nano \
    ncurses-term \
    net-tools \
    openssh-client \
    rsync \
    software-properties-common \
    sudo \
    systemd \
    task-xfce-desktop \
    unzip \
    usbutils \
    vim \
    wget \
    x11vnc

# remove unnecessary content
RUN \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# ensure default locale is generated
RUN locale-gen "en_US.UTF-8"

# flatten image
FROM scratch as stage2

COPY --from=stage1 / /

# Note: this section identical to skiff-core-defconfig

ENV container=docker \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Show the user list in lightdm
RUN \
  mkdir -p /etc/lightdm/lightdm.conf.d && \
  printf '[Seat:*]\ngreeter-hide-users=false\n' > /etc/lightdm/lightdm.conf.d/01-enable-users.conf

# Create the user 'core' which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
  adduser core \
  --no-create-home \
  --gecos "SkiffOS Core" \
  --shell /bin/bash \
  --disabled-password && \
  adduser core audio && \
  adduser core sudo && \
  adduser core root && \
  adduser core systemd-journal && \
  adduser core dialout && \
  adduser core plugdev && \
  mkdir -p /home/core/ && \
  chown core:core /home/core && \
  passwd -d core && \
  echo "core    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    (systemctl mask NetworkManager ModemManager wpa_supplicant) && \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*udev*' \
         -or -name '*freedesktop*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
