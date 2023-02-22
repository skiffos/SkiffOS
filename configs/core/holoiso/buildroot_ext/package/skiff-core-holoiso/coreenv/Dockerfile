# Imported from the holoiso release:
# losetup /dev/loop1 holoiso.iso
# partprobe /dev/loop1
# mkdir mtpt iso
# mount /dev/loop1p1 ./mtpt
# unsquashfs ./mtpt/arch/x86_64/airootfs.sfs
# umount ./mtpt
# rmdir mtpt
# losetup -d /dev/loop1
# cd ./squashfs-root/
# tar -c . | docker import - skiffos/skiff-core-holoiso:base
FROM quay.io/skiffos/skiff-core-holoiso:base as stage1

# setup environment
ENV container=docker

# update packages and add vim
RUN \
  echo "# <file system> <mount pt>    <type>  <options>     <dump>  <pass>" > /etc/fstab && \
  pacman --noconfirm -Syu vi \
    vim \
    sudo \
    base-devel \
    curl \
    git \
    htop \
    less \
    nano \
    net-tools \
    openssh \
    rsync \
    systemd \
    unzip \
    usbutils \
    wget \
    x11vnc \
  && rm -rf /var/cache/*

RUN systemctl set-default graphical.target && \
    systemctl mask zswap.service NetworkManager.service firewalld.service console-getty.service \
    udisks2-zram-setup@.service udisks2-zram-setup@zram0.service cups.service cups.path cups.socket \
    systemd-firstboot.service systemd-remount-fs.service sdcard-mount@mmcblk0p1.service obex.service && \
    rm -rf /etc/sddm.conf.d && \
    mkdir -p /etc/skiffos /etc/sddm.conf.d && \
    rm -f /usr/bin/holoiso-firstboot-config

# Add skiff core user.
RUN useradd -m core && \
    usermod -a -G wheel,rfkill core && \
    passwd -d core && \
    printf "# skiff core user\ncore    ALL=(ALL) NOPASSWD: ALL\n" > \
    /etc/sudoers.d/10-skiff-core && \
    chmod 0400 /etc/sudoers.d/10-skiff-core && \
    visudo -c -f /etc/sudoers.d/10-skiff-core

# Add startup script.
ADD init-skiff-core-holoiso.sh /etc/skiffos/init-skiff-core-holoiso.sh
ADD init-skiff-core-holoiso.service /etc/systemd/system/init-skiff-core-holoiso.service

# Add autologin.
ADD autologin.conf /etc/sddm.conf.d/autologin.conf

# Move the steam shortcuts to the desktop.
# Remove the entire "liveuser" user as well.
# Remove the install.desktop from the skel.
RUN \
    chmod +x /etc/skiffos/init-skiff-core-holoiso.sh && \
    systemctl enable init-skiff-core-holoiso.service && \
    userdel liveuser && \
    rm -rf /home/liveuser && \
    rm -f /usr/bin/holoiso-firstboot-config && \
    rm -f /etc/xdg/autostart/desktopshortcuts.desktop && \
    rm -f /etc/skel/Desktop/install.desktop && \
    cp /etc/holoinstall/post_install_shortcuts/steamos-gamemode.desktop \
      /etc/skel/Desktop && \
    ln -s /usr/share/applications/steam.desktop /etc/skel/Desktop/steam.desktop && \
    touch /etc/holoiso-oobe

# minimize image size by squashing OS to 1 layer.
# FROM scratch
# ENV container=docker
# COPY --from=stage1 / /

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
