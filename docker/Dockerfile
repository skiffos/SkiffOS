FROM scratch

ENV container docker
ENV init /lib/systemd/systemd
ENV LC_ALL C

ADD rootfs.tar /
USER root

RUN find /etc/systemd/system \
         /lib/systemd/system \
         -path '*.wants/*' \
         -not -name '*journald*' \
         -not -name '*systemd-tmpfiles*' \
         -not -name '*systemd-user-sessions*' \
         -not -name '*ssh*' \
         -exec rm \{} \;

RUN systemctl set-default multi-user.target && \
    systemctl mask tmp.mount && \
    touch /etc/skip-skiff-mounts && \
    touch /etc/skip-skiff-journal-mounts
COPY fstab /etc/fstab
COPY docker.service /etc/systemd/system/docker.service

VOLUME [ "/sys/fs/cgroup", "/mnt/persist", "/mnt/rootfs" ]
ENTRYPOINT ["/lib/systemd/systemd"]
