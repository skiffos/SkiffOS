# this was imported from the Manjaro iso
# download the latest .img.xz
# mount the 2nd partition to a path
# tar -c . | docker import - skiffos/skiff-core-pinephone-manjaro:base
# the SkiffOS images are periodically updated using the package manager.
FROM skiffos/skiff-core-pinephone-manjaro-kde:base

ADD ./fstab /etc/fstab

# setup environment
ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    container=docker

RUN pacman --noconfirm -Syu && rm -rf /var/cache/*
RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    rm /usr/lib/systemd/system/systemd-remount-fs.service || true; \
    ln -fs /dev/null /usr/lib/systemd/system/systemd-remount-fs.service; \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*NetworkManager*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{\} \; \
         -exec rm \{\} \;

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
