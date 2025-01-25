FROM linuxserver/steamos:latest as stage1

# setup environment
ENV LANG=C \
    container=docker

# update packages
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
    qt5-tools \
    maliit-keyboard \
    wget \
    x11vnc \
  && rm -rf /var/cache/*

RUN systemctl set-default graphical.target && \
    systemctl enable sddm && \
    printf "[General]\nDisplayServer=wayland\nGreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell\n\n[Wayland]\nCompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1" | sudo tee /etc/sddm.conf.d/10-wayland.conf && \
    systemctl mask zswap-arm.service NetworkManager.service firewalld.service \
      udisks2-zram-setup@.service udisks2-zram-setup@zram0.service \
      systemd-firstboot.service systemd-remount-fs.service \
      steamos-install-steamcl steamos-install-grub etc.mount

# add skiff core user
RUN useradd -m core && \
    printf "# skiff core user\ncore    ALL=(ALL) NOPASSWD: ALL\n" > \
    /etc/sudoers.d/10-skiff-core && \
    chmod 0400 /etc/sudoers.d/10-skiff-core && \
    visudo -c -f /etc/sudoers.d/10-skiff-core && \
    groupadd nopasswdlogin && \
    usermod -aG nopasswdlogin core && \
    printf "[Autologin]\nUser=core\nSession=plasma.desktop\nRelogin=false\n\n[General]\nNumlockOnWaylandEnable=true" | sudo tee /etc/sddm.conf.d/10-autologin.conf && \
    sed -i '0,/^[^#]/s//auth        sufficient  pam_succeed_if.so user ingroup nopasswdlogin\n&/' /etc/pam.d/sddm-autologin && \
    printf "[Unit]\nDescription=Fix Steam directory permissions\nAfter=graphical.target\n\n[Service]\nType=oneshot\nExecStart=/bin/chown core:core /home/core/.local/ /home/core/.local/share /home/core/.local/share/Steam\n\n[Install]\nWantedBy=graphical.target" | sudo tee /etc/systemd/system/fix-steam-perms.service && sudo systemctl enable fix-steam-perms.service

# minimize image size by squashing OS to 1 layer.
FROM scratch

ENV \
    container=docker \
    LANG=C

COPY --from=stage1 / /

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]

