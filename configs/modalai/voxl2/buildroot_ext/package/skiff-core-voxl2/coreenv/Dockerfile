# Matches the Ubuntu version from the Voxl system image.
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
# Hopefully this repository will be updated to be more secure in future.
#
# RUN echo 'deb [trusted=yes] http://voxl-packages.modalai.com/ qrb5165 stable' > /etc/apt/sources.list
RUN echo 'deb [trusted=yes] http://voxl-packages.modalai.com/ qrb5165 sdk-0.8 staging stable' > /etc/apt/sources.list.d/modalai.list

# Add voxl packages.
# Subject to the ModalAI EULAs and licenses.
# Note: more packages are available, see full list:
# http://voxl-packages.modalai.com/dists/qrb5165/stable/binary-arm64/
# Stub systemd so that systemctl doesn't fail.
# Currently not installable packages:
#  - voxl-px4: requires libfc-sensor (missing)
#  - voxl-suite: requires voxl-px4
RUN \
  echo "ModalAI 3.7.0" > /etc/version && \
  echo "/usr/lib64" > /etc/ld.so.conf.d/lib64.conf && \
	mkdir -p /etc/modalai && \
  mv /bin/systemctl /bin/systemctl.bak && \
  printf "#!/bin/bash\nexit 0\n" > /bin/systemctl && \
  chmod +x /bin/systemctl && \
  export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
    multiarch-support \
    qrb5165-dfs-server \
    qrb5165-imu-server \
    qrb5165-tflite \
    voxl-camera-server \
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

RUN touch /etc/ssh/sshd_not_to_be_run && \
    rm /etc/systemd/system/sshd.service && \
    systemctl set-default graphical.target && \
    systemctl mask tmp.mount persist.mount systemd-modules-load && \
    systemctl mask NetworkManager wpa_supplicant sshd haveged && \
    systemctl mask dhcpd systemd-timesyncd firewalld snapd

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
