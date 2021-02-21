FROM ubuntu:18.04 AS stage1

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
  libxml2-dev \
  libxslt-dev \
  locales \
  lsb-release \
  nano \
  net-tools \
  openssh-client \
  python3 \
  python3-dev \
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

# create cfs user
RUN \
  locale-gen "en_US.UTF-8" && \
  adduser cfs \
  --no-create-home \
  --gecos "NASA Fprime" \
  --shell /bin/bash \
  --disabled-password && \
  adduser cfs sudo && \
  adduser cfs root && \
  adduser cfs systemd-journal && \
  adduser cfs dialout && \
  adduser cfs plugdev && \
  mkdir -p /home/cfs/ && \
  chown -R cfs:cfs /home/cfs && \
  printf "# skiff core user\ncfs    ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/10-skiff-core && \
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

COPY --from=stage1 / /

# configure target software
RUN mkdir -p /opt && \
  git clone --recursive https://github.com/nasa/cfs.git /opt/cfs && \
  chown -R cfs:cfs /opt/
USER cfs

# disable -Werror due to cast-align errors on arm
RUN cd /opt/cfs && \
  cp cfe/cmake/Makefile.sample Makefile && \
  cp -r cfe/cmake/sample_defs sample_defs && \
  sed -i -e "/Werror/d" ./sample_defs/*.cmake && \
  make SIMULATION=native prep && \
  make -j4 && \
  sudo make install && \
  sudo git clean -xfd && \
  sudo git submodule foreach --recursive git clean -xfd

# TODO systemd configuration for core-cpu1
USER 0
WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
