# Based on the nasa/fprime repository Dockerfile, with modifications for use as
# a systemd-based Skiff Core container, similar to skiff-core-ubuntu.
#
# Reference: https://raw.githubusercontent.com/nasa/fprime/devel/docker/Dockerfile
FROM ubuntu:18.04 AS fprime-base

# setup environment
ENV container docker

RUN export DEBIAN_FRONTEND=noninteractive; \
  apt-get update && \
  apt-get dist-upgrade -y \
  -o "Dpkg::Options::=--force-confdef" \
  -o "Dpkg::Options::=--force-confnew" && \
  apt-get install -y \
  --no-install-recommends \
  -o "Dpkg::Options::=--force-confdef" \
  -o "Dpkg::Options::=--force-confnew" \
  bash \
  build-essential \
  cmake \
  curl \
  git \
  htop \
  locales \
  lsb-release \
  libxml2-dev \
  nano \
  net-tools \
  openssh-client \
  python3 \
  python3-pip \
  python3-setuptools \
  python3-venv \
  rsync \
  software-properties-common \
  sudo \
  systemd \
  time \
  unzip \
  usbutils \
  valgrind \
  vim \
  wget && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# create fprime user
RUN \
  locale-gen "en_US.UTF-8" && \
  adduser fprime \
  --no-create-home \
  --gecos "NASA Fprime" \
  --shell /bin/bash \
  --disabled-password && \
  adduser fprime sudo && \
  adduser fprime root && \
  adduser fprime systemd-journal && \
  adduser fprime dialout && \
  adduser fprime plugdev && \
  mkdir -p /home/fprime/ && \
  chown -R fprime:fprime /home/fprime && \
  printf "# skiff core user\nfprime    ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/10-skiff-core && \
  chmod 0400 /etc/sudoers.d/10-skiff-core && \
  visudo -c -f /etc/sudoers.d/10-skiff-core

# remove unnecessary systemd services
RUN systemctl set-default graphical.target && \
  systemctl mask tmp.mount && \
  systemctl mask kmod-static-nodes.service && \
  find /etc/systemd/system \
  /lib/systemd/system \
  \( -path '*.wants/*' \
  -name '*swapon*' \
  -or -name '*ntpd*' \
  -or -name '*resolved*' \
  -or -name '*NetworkManager*' \
  -or -name '*remount-fs*' \
  -or -name '*getty*' \
  -or -name '*systemd-sysctl*' \
  -or -name '*.mount' \
  -or -name '*remote-fs*' \) \
  -exec echo \{} \; \
  -exec rm \{} \;

# minimize image size by squashing OS to 1 layer.
FROM scratch

ENV \
  container=docker \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

COPY --from=fprime-base / /

# configure target software
RUN mkdir -p /opt/rpi /logs && \
  git clone --depth=1 https://github.com/raspberrypi/tools.git /opt/rpi/tools && \
  git clone https://github.com/nasa/fprime.git /opt/fprime && \
  chown -R fprime:fprime /opt/
USER fprime
RUN python3 -m venv /opt/fprime-venv/ && . /opt/fprime-venv/bin/activate && \
  pip install -U wheel setuptools pip && \
  pip install /opt/fprime/Fw/Python/ && \
  pip install /opt/fprime/Gds/ && \
  rm -r ~/.cache/pip && \
  chmod -R 775 /opt/fprime-venv

ENV VIRTUAL_ENV="/opt/fprime-venv" \
    PATH="/opt/fprime-venv/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

# for systemd
USER 0
WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
