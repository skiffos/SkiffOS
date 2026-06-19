# Imported from LibreELEC-Generic.x86_64-12.2.1.img.
FROM skiffos/skiff-core-libreelec:base AS stage1

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    container=docker

# SkiffOS owns the host mounts, kernel state, networking, and persistence.
RUN set -eux; \
    : > /etc/fstab; \
    mkdir -p /flash /storage /run /run/lock /tmp /var/log; \
    chmod 1777 /tmp; \
    rm -rf /run/* /tmp/* /var/cache/* 2>/dev/null || true; \
    mkdir -p /run/lock

RUN set -eux; \
    mkdir -p /etc/systemd/system; \
    for unit in \
      tmp.mount \
      var.mount \
      var-log.mount \
      dev-mqueue.mount \
      sys-fs-fuse-connections.mount \
      sys-kernel-config.mount \
      sys-kernel-debug.mount \
      sys-kernel-tracing.mount \
      swap.service \
      systemd-fsck-root.service \
      systemd-fsck@.service \
      systemd-growfs-root.service \
      systemd-remount-fs.service \
      systemd-sysctl.service \
      systemd-udev-settle.service \
      systemd-udev-trigger.service \
      systemd-udevd.service \
      systemd-udevd-control.socket \
      systemd-udevd-kernel.socket \
      connman.service \
      connman-vpn.service \
      iwd.service \
      iptables.service \
      rpcbind.service \
      rpcbind.socket \
      sshd.service \
      smbd.service \
      nmbd.service \
      avahi-daemon.service; \
    do \
      ln -sf /dev/null "/etc/systemd/system/${unit}"; \
    done

# Save space by squashing image.
FROM scratch

COPY --from=stage1 / /

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8 \
    container=docker

ENTRYPOINT ["/lib/systemd/systemd"]
