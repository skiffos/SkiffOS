# this was imported from the Manjaro iso
# download the latest .img.xz
# mount the 2nd partition to a path
# tar -c . | docker import - skiffos/skiff-core-pinephone-manjaro-phosh:base
# the SkiffOS images are periodically updated using the package manager.
FROM skiffos/skiff-core-pinephone-manjaro-phosh:base as stage1

ADD ./fstab /etc/fstab

# setup environment
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    container=docker

# remove unnecessary packages
# TODO: pacman just adds them back again, ignore them.
#RUN \
#    pacman --noconfirm -Rc linux-firmware anx7688-firmware uboot-firmware \
#      ov5640-firmware rtl8723bt-firmware-megi linux-pinephone

RUN pacman --noconfirm -Syu && \
    rm -rf /boot/*

RUN mkdir -p /etc/NetworkManager/conf.d; \
  printf '# SkiffOS manages WiFi networks.\nunmanaged-devices=interface-name:wlan0;interface-name:wlp3s0\n' \
  > /etc/NetworkManager/conf.d/10-skiffos-managed.conf; \
  chmod 0644 /etc/NetworkManager/conf.d/10-skiffos-managed.conf

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    systemctl disable pinephone-post-install.service && \
    rm /usr/lib/systemd/system/systemd-remount-fs.service || true; \
    ln -fs /dev/null /usr/lib/systemd/system/systemd-remount-fs.service; \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*bless-boot*' \
         -or -name '*mount-boot*' \
         -or -name '*initrd*' \
         -or -name '*resolved*' \
         -or -name '*remount-fs*' \
         -or -name '*lvm2*' \
         -or -name '*systemd-first-boot*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

# save space by squashing image
FROM scratch

COPY --from=stage1 / /

# setup environment
ENV LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8 \
  container=docker

ENTRYPOINT ["/lib/systemd/systemd"]
