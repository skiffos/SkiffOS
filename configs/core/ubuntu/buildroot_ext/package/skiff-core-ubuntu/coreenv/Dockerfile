FROM ubuntu:jammy as stage1

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    container=docker

# download packages list
# note: we remove the lists later & flatten the image.
RUN apt-get update

# Core packages, including ubuntu-desktop-minimal.
# Run "unminimize" to restore a full Ubuntu system.
RUN \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  --no-install-recommends \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  autotools-dev \
  build-essential \
  cups \
  curl \
  fonts-ubuntu \
  git \
  htop \
  less \
  locales \
  lsb-release \
  mesa-utils \
  nano \
  ncurses-term \
  neofetch \
  net-tools \
  openssh-client \
  rsync \
  software-properties-common \
  sudo \
  systemd \
  ubuntu-desktop-minimal \
  ubuntu-standard \
  unzip \
  usbutils \
  vim \
  xserver-xorg-input-all \
  yaru-theme-gnome-shell \
  yaru-theme-gtk \
  yaru-theme-icon \
  yaru-theme-sound \
  wget && \
  apt-get autoremove -y

# unminimize the system: restore GUI components.
RUN (yes | unminimize)

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

ENV container=docker \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

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
