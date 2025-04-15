# stage1: download and extract iso
FROM alpine:edge AS stage1

RUN apk upgrade --no-cache && \
    apk add --no-cache \
    ca-certificates \
    bash \
    wget \
    7zip \
    squashfs-tools

ENV CACHYOS_ISO_URL=https://cdn77.cachyos.org/ISO/desktop/250330/cachyos-desktop-linux-250330.iso

RUN wget -q "${CACHYOS_ISO_URL}" "${CACHYOS_ISO_URL}.sha256"
RUN sha256sum -c *.iso.sha256

RUN mkdir /mnt/iso /system && \
    7z x -o/mnt/iso *.iso && \
    unsquashfs -f -d /system /mnt/iso/arch/x86_64/airootfs.sfs && \
    rm -rf /mnt/iso *.iso*

# stage2: copy /system/ to /
FROM scratch AS stage2

COPY --from=stage1 /system/ /

# setup environment
ENV LANG=C \
    container=docker

# cachyos key
RUN pacman-key --init && \
    pacman-key --recv-keys F3B607488DB35A47 --keyserver hkp://keyserver.ubuntu.com:80 && \
    pacman-key --lsign-key 882DCFE48E2051D48E2562ABF3B607488DB35A47 && \
    rm -rf /var/cache/pacman/pkg/*

RUN pacman -Sy --noconfirm archlinux-keyring && \
    pacman-key --populate archlinux && \
    rm -rf /var/cache/pacman/pkg/*

ENV PKGS_TO_REMOVE="linux-cachyos linux-cachyos-nvidia-open linux-cachyos-zfs mkinitcpio mkinitcpio-archiso mkinitcpio-busybox mkinitcpio-nfs-utils mkinitcpio-openswap linux-firmware linux-firmware-marvell linux-firmware-whence sof-firmware amd-ucode intel-ucode grub refind syslinux os-prober efibootmgr hwdetect memtest86+ memtest86+-efi cachyos-calamares-qt6-grub virtualbox-guest-utils cachy-browser"

ENV PKGS_TO_IGNORE="linux linux-lts linux-zen linux-hardened linux-cachyos linux-cachyos-lto linux-cachyos-bore linux-cachyos-sched-ext mkinitcpio dracut booster linux-firmware linux-firmware-marvell linux-firmware-whence sof-firmware amd-ucode intel-ucode grub systemd-boot refind syslinux os-prober efibootmgr nvidia-utils zfs-utils linux-cachyos-nvidia-open linux-cachyos-zfs cachyos-calamares-qt6-grub virtualbox-guest-utils cachy-browser"

RUN pacman -Rns --noconfirm ${PKGS_TO_REMOVE}
RUN sed -i "s/^#IgnorePkg   =/IgnorePkg = $PKGS_TO_IGNORE/" /etc/pacman.conf

RUN \
  echo "# <file system> <mount pt>    <type>  <options>     <dump>  <pass>" >\
    /etc/fstab && \
  pacman --noconfirm -Syu vi \
    vim \
    sudo \
    base-devel \
    curl \
    git \
    htop \
    less \
    mesa-utils \
    nano \
    net-tools \
    openssh \
    rsync \
    systemd \
    ncdu \
    unzip \
    usbutils \
    wget \
  && rm -rf /var/cache/*

RUN systemctl set-default graphical.target && \
    systemctl mask zswap-arm.service NetworkManager.service firewalld.service \
    udisks2-zram-setup@.service udisks2-zram-setup@zram0.service \
    systemd-firstboot.service systemd-remount-fs.service

# add skiff core user
RUN useradd -m core && \
    printf "# skiff core user\ncore    ALL=(ALL) NOPASSWD: ALL\n" > \
    /etc/sudoers.d/10-skiff-core && \
    chmod 0400 /etc/sudoers.d/10-skiff-core && \
    visudo -c -f /etc/sudoers.d/10-skiff-core

# Remove other files
RUN pacman -Scc --noconfirm && \
    rm -f /etc/ssh/ssh_host_*_key* && \
    rm -rf /var/log/* && \
    rm -rf /tmp/* /var/tmp/*

# minimize image size by squashing OS to 1 layer.
FROM scratch

ENV \
    container=docker \
    LANG=C

COPY --from=stage2 / /

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
