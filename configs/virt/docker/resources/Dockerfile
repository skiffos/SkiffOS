FROM scratch

ADD rootfs.tar /

ENV container docker
ENV init /lib/systemd/systemd
ENV LC_ALL C

USER root
RUN find /etc/systemd/system \
         /usr/lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*udev*' \
         -or -name '*rdisc*' \
         -or -name '*freedesktop*' \
         -or -name '*persist-resize*' \
         -or -name '*NetworkManager*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    touch /etc/skip-skiff-mounts && \
    touch /etc/skip-skiff-journal-mounts

VOLUME [ "/sys/fs/cgroup", "/mnt/persist", "/mnt/rootfs" ]
ENTRYPOINT ["/usr/lib/systemd/systemd"]
