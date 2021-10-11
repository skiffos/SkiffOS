# this was imported from the Manjaro iso
# download the latest .img.xz
# mount the 2nd partition to a path
# tar -c . | docker import - skiffos/skiff-core-pinebook-manjaro:base
# the SkiffOS images are periodically updated using the package manager.
FROM skiffos/skiff-core-pinebook-manjaro-kde:base AS stage1

# setup environment
ENV LANG=C \
    container=docker

# update packages and add vim
# pacman --noconfirm -Syu vi vim
RUN \
  echo "# <file system> <mount pt>    <type>  <options>     <dump>  <pass>" >\
    /etc/fstab && \
  pacman --noconfirm -Rs uboot-pinebookpro linux linux-firmware && \
  rm -rf /etc/pacman.d/gnupg && \
  pacman-key --init && \
  pacman-key --refresh-keys && \
  pacman-key --populate archlinux manjaro archlinuxarm && \
  pamac update --force-refresh --no-confirm -a && \
  pacman --noconfirm -Syu vi vim && \
  rm -rf /var/cache/*

# note: pamac is manjaro-specific
RUN \
  pamac update --force-refresh --no-confirm -a && \
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
