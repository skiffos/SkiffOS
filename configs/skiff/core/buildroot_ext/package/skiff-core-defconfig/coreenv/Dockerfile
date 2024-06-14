# syntax=docker/dockerfile:1.8-labs
ARG DISTRO
FROM ${DISTRO:-debian:sid} AS stage1

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    DEBIAN_FRONTEND=noninteractive \
    container=docker

# Download apt cache
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get update

# Setup packages list to install
RUN cat > /etc/install-pkgs-list <<EOF
accountsservice
autotools-dev
build-essential
chromium
cups
curl
ffmpeg
git
gnupg
gnupg-utils
gpg-agent
htop
less
lightdm
locales
lsb-release
mesa-utils
mesa-vulkan-drivers
mplayer
nano
ncurses-term
net-tools
openssh-client
pavucontrol
pulseaudio
psmisc
python3-keyring
python3-launchpadlib
python3-secretstorage
rsync
software-properties-common
sudo
systemd
task-xfce-desktop
tmux
unzip
usbutils
vim
wget
x11vnc
xinput
xfce4-power-manager
EOF

RUN set -ex && \
    apt-get dist-upgrade -y && \
    apt-cache --generate pkgnames | \
      grep --line-regexp --fixed-strings --file /etc/install-pkgs-list | \
      xargs apt-get install -y \
        --no-install-recommends \
        --ignore-missing \
        -o "Dpkg::Options::=--force-confdef" \
    -o "Dpkg::Options::=--force-confnew" && \
    rm /etc/install-pkgs-list

# remove unnecessary content
RUN \
    apt-get autoremove -y && \
    apt-get clean -y && \
    rm -rf /var/lib/apt/lists/*

# ensure en_US locales are generated
RUN touch /etc/locale.gen && \
    sed -i 's/^#\(.*en_US.*\)/\1/' /etc/locale.gen && \
    locale-gen "en_US.UTF-8"

# flatten image
FROM scratch AS stage2

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
  if [ -d /etc/chromium.d ]; then \
    printf \
      "# Ignore the GPU blocklist and use GPU rendering.\nexport CHROMIUM_FLAGS=\"\$CHROMIUM_FLAGS --ignore-gpu-blocklist\"\n" >\
      /etc/chromium.d/ignore-gpu-blocklist; \
  fi

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

# TODO: Switch to using systemctl mask here.
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
