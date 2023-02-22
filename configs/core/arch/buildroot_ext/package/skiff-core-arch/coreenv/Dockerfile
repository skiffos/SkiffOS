FROM archlinux:latest as stage1

# setup environment
ENV LANG=C \
    container=docker

# update packages and add vim
# pacman --noconfirm -Syu vi vim
# pacman-key --refresh-keys
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
    unzip \
    usbutils \
    wget \
    x11vnc \
  && rm -rf /var/cache/*

# update packages and add xfce4
RUN \
    pacman --noconfirm -Syu xfce4 && \
    rm -rf /var/cache/*

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

# minimize image size by squashing OS to 1 layer.
FROM scratch

ENV \
    container=docker \
    LANG=C

COPY --from=stage1 / /

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
