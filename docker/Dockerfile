FROM scratch

ENV container docker
ENV init /lib/systemd/systemd
ENV LC_ALL C

ADD rootfs.tar /

USER root
RUN find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*udev*' \
         -or -name '*freedesktop*' \
         -or -name '*persist-resize*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    touch /etc/skip-skiff-mounts && \
    touch /etc/skip-skiff-journal-mounts
COPY fstab /etc/fstab

VOLUME [ "/sys/fs/cgroup", "/mnt/persist", "/mnt/rootfs" ]
ENTRYPOINT ["/lib/systemd/systemd"]
