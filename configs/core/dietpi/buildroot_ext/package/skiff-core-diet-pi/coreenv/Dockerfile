# Based on the skiff/core defconfig (Ubuntu) Dockerfile, with modifications for
# DietPi installation and setup.

FROM debian:bullseye as stage1

# setup environment
ENV LANG=C.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    container=docker

# Download apt cache (we clear it later)
RUN apt-get update

# Core packages
RUN export DEBIAN_FRONTEND=noninteractive; \
    apt-get update && \
    apt-get dist-upgrade -y && \
    apt-get install -y  \
    --no-install-recommends \
    -o "Dpkg::Options::=--force-confdef"  \
    -o "Dpkg::Options::=--force-confnew"  \
    autotools-dev \
    bash-completion \
    build-essential \
    bzip2 \
    ca-certificates \
    cron \
    cups \
    curl \
    dirmngr \
    ethtool \
    fake-hwclock \
    git \
    gnupg \
    htop \
    ifupdown \
    iputils-ping \
    kmod \
    locales \
    lsb-release \
    nano \
    ncurses-term \
    net-tools \
    openssh-client \
    p7zip \
    parted \
    procps \
    psmisc \
    rfkill \
    rsync \
    software-properties-common \
    sudo \
    systemd \
    systemd-sysv \
    tzdata \
    udev \
    unzip \
    usbutils \
    vim \
    whiptail \
    wget && \
    apt-get autoremove -y

# Create the user 'dietpi' which will be the usual userspace account
# Also allow dietpi to run stuff as sudo without a password.
RUN \
  adduser dietpi \
  --no-create-home \
  --gecos "SkiffOS Core" \
  --shell /bin/bash \
  --disabled-password && \
  adduser dietpi audio && \
  adduser dietpi sudo && \
  adduser dietpi root && \
  adduser dietpi systemd-journal && \
  adduser dietpi dialout && \
  adduser dietpi plugdev && \
  mkdir -p /home/dietpi/ && \
  chown dietpi:dietpi /home/dietpi && \
  passwd -d dietpi && \
  echo "dietpi    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Note: this section differs from skiff-core-defconfig
RUN cd /usr/src && \
    git clone https://github.com/MichaIng/DietPi.git && \
    cd ./DietPi && \
    git checkout --detach 701c30575f7c59e15a72e33f15991eb5fad2bfe6

# Prepare system for DietPi
RUN cd /usr/src/DietPi && \
    export GITBRANCH=master && \
    export IMAGE_CREATOR="skiffos" && \
    export PREIMAGE_INFO="https://github.com/skiffos/skiffos" && \
    export HW_MODEL=22 && \
    export WIFI_REQUIRED=0 && \
    export DISTRO_TARGET=6 && \
    mkdir -p /boot/dietpi /var/tmp/dietpi /var/lib/dietpi/dietpi-software/ && \
    cp -Rf ./dietpi/. /boot/dietpi/ && \
    cp -Rf ./rootfs/. / && \
    cp dietpi.txt /boot/ && \
    cp README.md /boot/dietpi-README.md && \
    cp LICENSE /boot/dietpi-LICENSE.txt && \
    cp CHANGELOG.txt /boot/dietpi-CHANGELOG.txt && \
    chmod -R +x /boot/dietpi /var/lib/dietpi/services /etc/cron.*/dietpi && \
    echo "$IMAGE_CREATOR" > /boot/dietpi/.prep_info && \
    echo "$PREIMAGE_INFO" >> /boot/dietpi/.prep_info && \
    cp LICENSE /var/lib/dietpi/license.txt && \
    echo "22" > /etc/.dietpi_hw_model_identifier && \
    /boot/dietpi/func/dietpi-obtain_hw_model && \
    echo 2 > /boot/dietpi/.install_stage && \
    /boot/dietpi/func/dietpi-set_software ntpd-mode "0" && \
    echo "PATH=\$PATH:/boot/dietpi" > /etc/profile.d/dietpi-path.sh && \
    sed -ie "s/AUTO_SETUP_SSH_SERVER_INDEX=-1/AUTO_SETUP_SSH_SERVER_INDEX=0/g" /boot/dietpi.txt && \
    sed -ie "s/AUTO_SETUP_LOGGING_INDEX=-1/AUTO_SETUP_LOGGING_INDEX=0/g" /boot/dietpi.txt && \
    chmod +x /etc/profile.d/dietpi-path.sh && \
    cd / && rm -rf /usr/src/DietPi

# Run dietpi setup scripts
RUN /boot/dietpi/func/dietpi-set_software apt-mirror default && \
    mkdir -p /run/dietpi /var/tmp/dietpi/logs && \
    ln -sfv /etc/profile.d/bash_completion.sh /etc/bashrc.d/dietpi-bash_completion.sh && \
    mkdir -pv /var/lib/dietpi/{postboot.d,dietpi-software/installed} && \
    mkdir -pv /var/tmp/dietpi/logs/dietpi-ramlog_store && \
    mkdir -pv /mnt/{dietpi_userdata,samba,ftp_client,nfs_client} && \
    chown -R dietpi:dietpi /var/lib/dietpi /mnt/{dietpi_userdata,samba,ftp_client,nfs_client} && \
    find /var/lib/dietpi /mnt/{dietpi_userdata,samba,ftp_client,nfs_client} -type d -exec chmod 0775 {} + && \
    systemctl enable dietpi-ramlog dietpi-preboot dietpi-boot dietpi-postboot dietpi-kill_ssh && \
    systemctl mask sshd

# DietPi cleanup
RUN (rm -Rv /var/cache/apparmor || true) && \
    (rm -Rfv /var/lib/dhcp/{,.??,.[^.]}* || true) && \
    ([[ -d '/usr/share/calendar' ]] && rm -vR /usr/share/calendar || true) && \
    (rm -Rfv /var/backups/{,.??,.[^.]}* || true) && \
    (rm -fv /var/cache/debconf/*-old || true) && \
    (rm -fv /var/lib/dpkg/*-old || true) && \
    (rm -Rfv /{root,home/*}/.{bash_history,nano_history,wget-hsts,cache,local,config,gnupg,viminfo,dbus,gconf,nano,vim,zshrc,oh-my-zsh} || true)

# Cleanup any data we don't need.
RUN rm -rf /var/lib/apt/lists/*

# Locale-gen
RUN locale-gen "en_US.UTF-8"

FROM scratch as stage2

COPY --from=stage1 / /

# Note: this section identical to skiff-core-defconfig

ENV container=docker \
  LANG=en_US.UTF-8 \
  LANGUAGE=en_US:en \
  LC_ALL=en_US.UTF-8

RUN systemctl set-default graphical.target && \
    systemctl mask tmp.mount && \
    find /etc/systemd/system \
         /lib/systemd/system \
         \( -path '*.wants/*' \
         -name '*swapon*' \
         -or -name '*ntpd*' \
         -or -name '*resolved*' \
         -or -name '*udev*' \
         -or -name '*freedesktop*' \
         -or -name '*remount-fs*' \
         -or -name '*getty*' \
         -or -name '*systemd-sysctl*' \
         -or -name '*.mount' \
         -or -name '*remote-fs*' \) \
         -exec echo \{} \; \
         -exec rm \{} \;

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
