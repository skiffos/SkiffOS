FROM alpine:edge as downloader

# download sources
ENV L4T_URL https://developer.download.nvidia.com/embedded/L4T/r35_Release_v1.0/Release/Tegra_Linux_Sample-Root-Filesystem_R35.1.0_aarch64.tbz2
ENV L4T_TAR tegra-sample-rootfs.tbz2
RUN mkdir -p /data && \
    wget -q "${L4T_URL}" -O /data/${L4T_TAR}

# extract
RUN echo "Extracting rootfs tbz2 to /target..." && \
    mkdir -p /target && cd /target && \
    tar -xf /data/tegra-sample-rootfs.tbz2

# extract to /
FROM scratch as stage2

COPY --from=downloader /target /

# update packages
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
    htop \
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

FROM scratch

COPY --from=stage2 / /

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    container=docker

RUN \
    adduser nvidia \
    --gecos "SkiffOS Core" \
    --shell /bin/bash \
    --disabled-password && \
    adduser nvidia audio && \
    adduser nvidia sudo && \
    adduser nvidia systemd-journal && \
    adduser nvidia dialout && \
    adduser nvidia plugdev && \
    mkdir -p /home/nvidia/ && \
    chown nvidia:nvidia /home/nvidia && \
    passwd -d nvidia && \
    echo "nvidia	ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/nvidia && \
    chmod 0440 /etc/sudoers.d/nvidia

RUN touch /etc/ssh/sshd_not_to_be_run && \
    rm /etc/systemd/system/sshd.service && \
    systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    systemctl mask NetworkManager wpa_supplicant sshd haveged && \
    systemctl mask dhcpd systemd-timesyncd firewalld nvwifibt snapd

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
