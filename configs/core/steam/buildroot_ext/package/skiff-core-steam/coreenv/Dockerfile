FROM linuxserver/steamos:latest as stage1

# setup environment
ENV LANG=C \
    container=docker

# drop stuff we don't need from the base image
RUN \
    userdel abc && \
    userdel kasm-user && \
    rm -rf /etc/s6-overlay && \
    pacman --noconfirm -R sunshine sunshine-debug nginx

# update packages
RUN \
  echo "# <file system> <mount pt>    <type>  <options>     <dump>  <pass>" >\
    /etc/fstab && \
  pacman --noconfirm -Syu \
    vi \
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
    kscreen \
    wget \
  && rm -rf /var/cache/*

RUN systemctl set-default graphical.target && \
    systemctl enable sddm && \
    printf "[General]\nDisplayServer=wayland\nGreeterEnvironment=QT_WAYLAND_SHELL_INTEGRATION=layer-shell\n\n[Wayland]\nCompositorCommand=kwin_wayland --drm --no-lockscreen --no-global-shortcuts --locale1" | sudo tee /etc/sddm.conf.d/10-wayland.conf && \
    sed -i -z 's/#HandlePowerKey=poweroff\n#HandlePowerKeyLongPress=ignore/HandlePowerKey=suspend\nHandlePowerKeyLongPress=poweroff/' /etc/systemd/logind.conf && \
    systemctl mask zswap-arm.service NetworkManager.service firewalld.service \
      udisks2-zram-setup@.service udisks2-zram-setup@zram0.service \
      systemd-firstboot.service systemd-remount-fs.service \
      steamos-install-steamcl steamos-install-grub etc.mount

# add skiff core user
RUN \
    useradd -m core && \
    printf "# skiff core user\ncore    ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/10-skiff-core && \
    chmod 0400 /etc/sudoers.d/10-skiff-core && \
    visudo -c -f /etc/sudoers.d/10-skiff-core && \
    groupadd nopasswdlogin && \
    passwd -d core && \
    usermod -aG nopasswdlogin core && \
    printf "[Autologin]\nUser=core\nSession=plasma.desktop\nRelogin=false\n\n[General]\nNumlockOnWaylandEnable=true" | sudo tee /etc/sddm.conf.d/10-autologin.conf && \
    sed -i '0,/^[^#]/s//auth        sufficient  pam_succeed_if.so user ingroup nopasswdlogin\n&/' /etc/pam.d/sddm-autologin && \
    printf "[Unit]\nDescription=Fix Steam directory permissions\nAfter=graphical.target\n\n[Service]\nType=oneshot\nExecStart=/bin/chown core:core /home/core/.local/ /home/core/.local/share /home/core/.local/share/Steam\n\n[Install]\nWantedBy=graphical.target" | sudo tee /etc/systemd/system/fix-steam-perms.service && sudo systemctl enable fix-steam-perms.service && \
    printf '[Desktop Entry]\nExec=/usr/bin/steam -gamepadui %%U\nType=Application\nName=Steam GamePad UI\nTerminal=false\nX-KDE-RunOnDiscreteGpu=true\nPrefersNonDefaultGPU=true' > /home/core/.config/autostart/steam.desktop && \
    printf '[General]\nloginMode=emptySession' > /home/core/.config/ksmserverrc && \
    printf '[AC][Display]\nLockBeforeTurnOffDisplay=true\nTurnOffDisplayIdleTimeoutSec=-1\nTurnOffDisplayWhenIdle=false\n[AC][SuspendAndShutdown]\nLidAction=1\nPowerButtonAction=1\n[Battery][Display]\nDimDisplayIdleTimeoutSec=600\nLockBeforeTurnOffDisplay=true\nTurnOffDisplayIdleTimeoutSec=-1\nTurnOffDisplayWhenIdle=false\n[Battery][SuspendAndShutdown]\nAutoSuspendIdleTimeoutSec=300\nLidAction=1\nPowerButtonAction=1\n[LowBattery][Display]\nDimDisplayIdleTimeoutSec=-1\nDimDisplayWhenIdle=false\nLockBeforeTurnOffDisplay=true\nTurnOffDisplayIdleTimeoutSec=-1\nTurnOffDisplayWhenIdle=false\nUseProfileSpecificDisplayBrightness=false\n[LowBattery][SuspendAndShutdown]\nAutoSuspendAction=1\nAutoSuspendIdleTimeoutSec=600\nLidAction=1\nPowerButtonAction=1' > /home/core/.config/powerdevilrc && \
    printf "[Daemon]\nAutolock=false\nLockOnResume=false\nTimeout=0\n" > /etc/xdg/kscreenlockerrc && \
    cp /etc/xdg/kscreenlockerrc /home/core/.config/kscreenlockerrc && \
    rm -f /home/core/Desktop/Return.desktop && \
    chown -R core:core /home/core

# minimize image size by squashing OS to 1 layer.
FROM scratch

ENV \
    container=docker \
    LANG=C

COPY --from=stage1 / /

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
