ARG DISTRO
FROM ${DISTRO:-debian:bookworm} as stage1

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
    accountsservice \
    autotools-dev \
    build-essential \
    chromium \
    cups \
    curl \
    git \
    gnupg \
    gnupg-utils \
    gpg-agent \
    htop \
    less \
    lightdm \
    locales \
    lsb-release \
    mesa-utils \
    mesa-vulkan-drivers \
    ffmpeg \
    nano \
    ncurses-term \
    net-tools \
    openssh-client \
    pavucontrol \
    pulseaudio \
    python3-keyring \
    python3-secretstorage \
    python3-launchpadlib \
    rsync \
    software-properties-common \
    sudo \
    systemd \
    task-xfce-desktop \
    unzip \
    usbutils \
    vim \
    wget \
    xfce4-power-manager \
    x11vnc

# remove unnecessary content
RUN \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# ensure en_US locales are generated
RUN sed -i 's/^#\(.*en_US.*\)/\1/' /etc/locale.gen && \
    locale-gen "en_US.UTF-8"

# flatten image
FROM scratch as stage2

COPY --from=stage1 / /

ENV container=docker \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

# Show the user list in lightdm
# force Chromium to use the GPU
RUN \
  mkdir -p /etc/lightdm/lightdm.conf.d && \
  printf '[Seat:*]\ngreeter-hide-users=false\n' > /etc/lightdm/lightdm.conf.d/01-enable-users.conf && \
  printf \
    "# Ignore the GPU blocklist and use GPU rendering.\nexport CHROMIUM_FLAGS=\"\$CHROMIUM_FLAGS --ignore-gpu-blocklist\"\n" >\
    /etc/chromium.d/ignore-gpu-blocklist

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
