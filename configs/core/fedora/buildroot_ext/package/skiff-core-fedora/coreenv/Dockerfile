FROM docker.io/library/fedora:37 as stage1

# setup environment
ENV container=docker

# Exclude linux-firmware.
RUN printf 'exclude=*-firmware*' >> /etc/dnf/dnf.conf

# Update packages.
RUN dnf update -y

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

# remove unnecessary content
RUN \
  dnf remove -y linux-firmware\* && \
  dnf autoremove -y && \
  rm -rf /var/lib/dnf/repos /var/cache/dnf && \
  dnf clean packages

# flatten image
FROM scratch as stage2
ENV container=docker
COPY --from=stage1 / /

RUN systemctl set-default graphical.target && \
    systemctl mask \
      NetworkManager-dispatcher.service \
      NetworkManager-wait-online.service \
      NetworkManager.service \
      auditd.service \
      chronyd.service \
      console-getty.service \
      firewalld.service \
      serial-getty@.service \
      sshd.service \
      systemd-networkd-wait-online.service \
      systemd-networkd.service \
      systemd-oomd.service \
      tmp.mount \
      wpa_supplicant.service

# Create the user 'core' which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
  groupadd sudo && \
  adduser core \
    --create-home \
    --shell /bin/bash \
    -G audio,sudo,video,dialout,disk,adm && \
  passwd -d core && \
  echo "%sudo    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/sudo && \
  chmod 0440 /etc/sudoers.d/sudo

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
