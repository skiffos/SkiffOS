# Download the linux4tegra sources including nvidia packages.
# Subject to the NVIDIA Customer License.
FROM ubuntu:18.04 AS nvsources

# install wget + make data dir
RUN mkdir -p /data /sources && \
  export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confold"  \
  build-essential \
  rsync \
  lsb-release \
  wget curl git unzip \
  autotools-dev locales \
  && apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# download sources
ENV L4T_URL https://developer.nvidia.com/embedded/L4T/r32_Release_v7.1/t210/jetson-210_linux_r32.7.1_aarch64.tbz2
ENV L4T_TAR linux4tegra-aarch64.tbz2
RUN wget -q "${L4T_URL}" -O /data/${L4T_TAR}

# extract sources
# move kernel debs into nv debs dir
RUN mkdir -p /sources/linux4tegra && \
  tar --strip-components=1 -xf /data/${L4T_TAR} \
  -C /sources/linux4tegra && \
  mv /sources/linux4tegra/kernel/*.deb \
  /sources/linux4tegra/nv_tegra/l4t_deb_packages/ && \
  mv /sources/linux4tegra/tools/*.deb \
  /sources/linux4tegra/nv_tegra/l4t_deb_packages/

# configure debian packages to point to mock paths
COPY ./patch-debs.bash /sources/patch-debs.bash
RUN mkdir -p /sources/l4t_debs_workdir /sources/l4t_debs_patched && \
  cd /sources/l4t_debs_workdir && \
  bash /sources/patch-debs.bash && \
  cd ../ && rm -rf /sources/l4t_debs_workdir

# Ubuntu upstream
FROM ubuntu:18.04 as stage2

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    container=docker \
    L4T_VERSION=32.6.1 \
    L4T_SOC=t186

# All packages, including requisite packages for nvidia.
# Also installs l4t_deb_packages.
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  autotools-dev \
  build-essential \
  curl \
  git \
  locales \
  software-properties-common \
  sudo \
  systemd \
  unzip \
  usbutils \
  vim \
  libunwind8 \
  sed \
  locales \
  wget && \
  apt-get autoremove -y

# copy l4t_deb_packages
COPY --from=nvsources /sources/l4t_debs_patched \
  /usr/src/l4t_deb_packages

# copy nv_boot_control
COPY --from=nvsources /sources/linux4tegra/bootloader/nv_boot_control.conf \
  /etc/nv_boot_control.conf

# setup nv-boot-control.conf
# Set board spec: BOARD_ID-FAB-BOARDSKU-BOARDREV-NV_PRODUCTION-CHIP_REV-BOARD_NAME-ROOTFS_DEV
#
#  BOARDID  BOARDSKU  FAB  BOARDREV
#  --------------------------------+--------+---------+----+---------
#  jetson-tx1                       2180     0000      400  N/A
#  jetson-tx2                       3310     1000      B02  N/A
#  jetson-xavier                    2888     0001      400  H.0
#  jetson-nano-emmc                 3448     0002      200  N/A
#  jetson-xavier-nx-devkit-emmc     3668     0001      100  N/A
#  --------------------------------+--------+---------+----+---------
RUN rootfs_dir=/; \
  BOARDID=2180; BOARDSKU=1000; CHIPID="0x18"; FAB=B02; FUSELEVEL=fuselevel_production; \
  hwchiprev="0"; ext_target_board="jetson_tx2_devkit"; target_rootdev="mmcblk0p1"; \
  ota_boot_dev="/dev/mmcblk0boot0"; ota_gpt_dev="/dev/mmcblk0boot1"; \
  spec="${BOARDID}-${FAB}-${BOARDSKU}-${BOARDREV}-1-${hwchiprev}-${ext_target_board}-${target_rootdev}"; \
  sed -i '/TNSPEC/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TNSPEC ${spec}" "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i '/TEGRA_CHIPID/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TEGRA_CHIPID ${CHIPID}" "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i '/TEGRA_OTA_BOOT_DEVICE/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TEGRA_OTA_BOOT_DEVICE ${ota_boot_dev}" "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i '/TEGRA_OTA_GPT_DEVICE/d' "${rootfs_dir}/etc/nv_boot_control.conf"; \
  sed -i "$ a TEGRA_OTA_GPT_DEVICE ${ota_gpt_dev}" "${rootfs_dir}/etc/nv_boot_control.conf"

# setup device-tree path for reference for debs
RUN mkdir -p /etc/tegra-soc/device-tree && \
  echo "nvidia,quillnvidia,p2597-0000+p3310-1000nvidia,tegra186" >\
    /etc/tegra-soc/device-tree/compatible && \
  mkdir -p /opt/nvidia/l4t-packages && \
  touch /opt/nvidia/l4t-packages/.nv-l4t-disable-boot-fw-update-in-preinstall

# linux4tegra
RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get autoremove -y && \
  apt-get dist-upgrade -y && \
  apt-get install -y  \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  mesa-utils libgles2-mesa-dev libsdl2-dev libblas3 liblapack3 && \
  apt-get install -y \
  -o "Dpkg::Options::=--force-confdef"  \
  -o "Dpkg::Options::=--force-confnew"  \
  /usr/src/l4t_deb_packages/*.deb && \
  apt-get autoremove -y && \
  apt-mark hold nvidia-l4t-kernel nvidia-l4t-initrd nvidia-l4t-kernel-dtbs && \
  rm -rf /var/lib/apt/lists/* && \
  rm -rf /usr/src/l4t_deb_packages

# re-pack base image for performance
FROM scratch

COPY --from=stage2 / /

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    container=docker \
    L4T_VERSION=32.6.1 \
    L4T_SOC=t186

# adjust the installed lists
RUN sed -i -e "s/<SOC>/${L4T_SOC}/g" /etc/apt/sources.list.d/nvidia-l4t-apt-source.list

# additional desktop packages
# chromium-browser
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y  \
    -o "Dpkg::Options::=--force-confdef"  \
    -o "Dpkg::Options::=--force-confold"  \
    ark \
    cups \
    desktop-base \
    firefox \
    fonts-ubuntu \
    gwenview \
    htop \
    kate \
    kcalc \
    kde-spectacle \
    lightdm \
    lightdm-gtk-greeter \
    locales \
    lsb-release \
    lxde \
    mplayer \
    nano \
    ncurses-term \
    net-tools \
    okular \
    openssh-client \
    rsync \
    unzip \
    usbutils \
    vim \
    vlc \
    x11-apps \
    x11vnc \
    xorg \
    xserver-xorg-input-all \
    wget && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

RUN \
  adduser nvidia \
  --no-create-home \
  --gecos "NVIDIA User" \
  --shell /bin/bash \
  --disabled-password && \
  adduser nvidia sudo && \
  adduser nvidia root && \
  adduser nvidia systemd-journal && \
  adduser nvidia dialout && \
  adduser nvidia video && \
  adduser nvidia plugdev && \
  echo "nvidia:nvidia" | chpasswd && \
  mkdir -p /home/nvidia/.cache/ && \
  chown -R nvidia:nvidia /home/nvidia

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    (systemctl mask NetworkManager wpa_supplicant || true) && \
    (systemctl mask dhcpd || true) && \
    rm /etc/systemd/system/nvwifibt.service && \
    echo "nvidia	ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
