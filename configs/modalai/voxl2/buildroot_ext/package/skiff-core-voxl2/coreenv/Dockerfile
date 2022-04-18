FROM ubuntu:18.04

# Install / upgrade base packages first.
RUN \
  export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
  build-essential autotools-dev locales usbutils sed \
  rsync sudo software-properties-common vim \
  lsb-release wget curl git unzip \
  autotools-dev locales systemd wget \
  && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# Add voxl2 package sources and keys.
# WARNING: This URL is HTTP (not secure) & the packages are unsigned!
# To force apt to use the unsigned packages, set trusted=yes.
# Hopefully this repository will be updated to be secure.
# RUN add-apt-repository 'deb [trusted=yes] http://voxl-packages.modalai.com/ qrb5165 dev staging stable'
# RUN echo 'deb [trusted=yes] http://voxl-packages.modalai.com/ qrb5165 dev staging stable' >> /etc/apt/sources.list
RUN echo 'deb [trusted=yes] http://voxl-packages.modalai.com/ qrb5165 stable' > /etc/apt/sources.list.d/modalai.list


# Add voxl packages.
# Subject to the ModalAI EULAs and licenses.
# Note: more packages are available, see full list:
# http://voxl-packages.modalai.com/dists/qrb5165/dev/binary-arm64/
# Stub systemd so that systemctl doesn't fail.
RUN \
  mv /bin/systemctl /bin/systemctl.bak && \
  printf "#!/bin/bash\nexit 0\n" > /bin/systemctl && \
  chmod +x /bin/systemctl && \
  export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
    qrb5165-camera-server \
    qrb5165-dfs-server \
    qrb5165-imu-server \
    qrb5165-system-tweaks \
    qrb5165-tflite \
    voxl-suite \
    voxl-utils \
  && apt-get autoremove -y && \
  mv /bin/systemctl.bak /bin/systemctl

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
