FROM docker.io/library/fedora:37 as stage1

# setup environment
ENV container=docker

# Update packages.
RUN dnf update -y

# Exclude linux-firmware.
RUN printf 'exclude=*-firmware*' >> /etc/dnf/dnf.conf

# Core packages.
# You can check available groups with dnf grouplist
RUN dnf install -y systemd @basic-desktop-environment

# remove unnecessary content
RUN \
  dnf remove -y linux-firmware\* && \
  dnf autoremove -y && \
  rm -rf /var/lib/dnf/repos /var/cache/dnf

# flatten image
FROM scratch as stage2
ENV container=docker
COPY --from=stage1 / /

RUN systemctl set-default graphical.target && \
    systemctl mask \
      console-getty.service \
      serial-getty@.service \
      NetworkManager.service \
      NetworkManager-wait-online.service \
      NetworkManager-dispatcher.service \
      wpa_supplicant.service \
      systemd-networkd.service \
      systemd-networkd-wait-online.service \
      tmp.mount

# Create the user 'core' which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
	groupadd sudo && \
  adduser core \
    --no-create-home \
    --shell /bin/bash \
    -G audio,sudo,video,dialout,disk,adm && \
  passwd -d core && \
  echo "%sudo    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/sudo && \
  chmod 0440 /etc/sudoers.d/sudo

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
