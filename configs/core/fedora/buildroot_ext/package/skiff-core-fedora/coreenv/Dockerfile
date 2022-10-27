# You can also import an existing Fedora image with:
# cd ./path/to/fedora/root
# tar -c . | docker import - skiffos/skiff-core-fedora:base
# cd /path/to/dockerfile/dir
# docker build -t skiffos/skiff-core-fedora --build-arg DISTRO=skiffos/skiff-core-fedora:base .
ARG DISTRO
FROM ${DISTRO:-docker.io/library/fedora:37} as stage1

# setup environment
ENV container=docker

# Update packages.
RUN dnf upgrade --refresh -y --allowerasing --skip-broken

# Update packages, pass 2.
RUN dnf upgrade -y --allowerasing --best

# Install versionlock
RUN dnf install -y python3-dnf-plugin-versionlock

# Exclude linux-firmware and kernel-core.
RUN (yum remove --noautoremove -y linux-firmware\* || true) && \
    (dnf versionlock add kernel\* || true) && \
    printf 'exclude=*-firmware*' >> /etc/dnf/dnf.conf && \
    rm -rf /usr/lib/modules/* /usr/src/kernels/* /boot/*

# Core packages.
RUN dnf install -y \
      curl \
      ethtool \
      git \
      htop \
      nano \
      net-tools \
      rsync \
      sudo \
      systemd \
      vim

# XFCE desktop environment.
# You can check available groups with dnf grouplist
# Another option (openbox): @basic-desktop-environment
RUN dnf install -y @xfce-desktop-environment

# Remove unnecessary locales, disable fstab
RUN \
    mkdir -p /etc/rpm && \
    echo '%_install_langs C:en:en_US:en_US.UTF-8' > /etc/rpm/macros.image-language-conf && \
    echo "" > /etc/fstab && \
    dnf reinstall -y glibc-common

# Minimize disk size: remove unnecessary packages
RUN \
    dnf remove -y texlive\* mint-\*-icons\* && \
    dnf autoremove -y && \
    dnf clean packages && \
    rm -rf /var/lib/dnf/repos /var/cache/dnf /usr/lib/firmware

# flatten image
FROM scratch as stage2
ENV container=docker
COPY --from=stage1 / /

RUN systemctl set-default graphical.target && \
    systemctl mask \
      avahi-daemon.service \
      NetworkManager-dispatcher.service \
      NetworkManager-wait-online.service \
      NetworkManager.service \
      auditd.service \
      chronyd.service \
      console-getty.service \
      firewalld.service \
      serial-getty@.service \
      haveged.service \
      sshd.service \
      systemd-networkd-wait-online.service \
      systemd-networkd.service \
      systemd-oomd.service \
      systemd-remount-fs.service \
      tmp.mount \
      wpa_supplicant.service

# Create the user 'core' which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
  groupadd sudo && \
  adduser core \
    --create-home \
    --shell /bin/bash \
    -G audio,sudo,video,dialout,disk,adm,systemd-journal && \
  passwd -d core && \
  echo "%sudo    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/sudo && \
  chmod 0440 /etc/sudoers.d/sudo

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
