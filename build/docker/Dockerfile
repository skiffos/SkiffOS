FROM ubuntu:noble

LABEL maintainers="Christian Stewart <christian@paral.in>, razlix77 <razlix77@gmail.com>"

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y \
    git-core \
    gnupg \
    flex \
    bison \
    gperf \
    build-essential \
    zip \
    curl \
    zlib1g-dev \
    gcc-multilib \
    g++-multilib \
    libc6-dev-i386 \
    x11proto-core-dev \
    libx11-dev \
    lib32z1-dev \
    ccache \
    libgl1-mesa-dev \
    libxml2-utils \
    xsltproc \
    unzip \
    device-tree-compiler \
    fish \
    libfile-which-perl \
    sed \
    make \
    binutils \
    gcc \
    g++ \
    bash \
    patch \
    gzip \
    bzip2 \
    perl \
    tar \
    cpio \
    python3 \
    rsync \
    file \
    bc \
    libmpc3 \
    git \
    repo \
    texinfo \
    pkg-config \
    cmake \
    tree \
    udev \
    dosfstools \
    parted \
    sudo \
    genext2fs \
    time \
    wget \
    liblz4-tool \
    && apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY <<'EOF' /entrypoint.bash
#!/bin/bash
set -e

TUIDGID=($SKIFF_TUIDGID)
TUID=${TUIDGID[0]}
TGID=${TUIDGID[1]}

NAME="skiffos"
addgroup --gid ${TGID} ${NAME}
adduser \
    --gid ${TGID} \
    --uid ${TUID} \
    --shell /bin/bash \
    --disabled-login \
    --gecos "" \
    ${NAME} >/dev/null

ARGS=$@
if [ "$ARGS" != "" ]; then
    ARGS="-c ${ARGS}"
fi
sudo -u \#${TUID} -- /bin/bash +e $ARGS
EOF
RUN chmod +x /entrypoint.bash

RUN git config --global --add safe.directory /skiffos

WORKDIR /skiffos

ENTRYPOINT ["/entrypoint.bash"]
