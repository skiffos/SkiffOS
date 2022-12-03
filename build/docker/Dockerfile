FROM ubuntu:kinetic

# Maintainers:
#  Christian Stewart <christian@paral.in>
#  razlix77 <razlix77@gmail.com>

ENV KERNEL_BUILDDEPS="git-core gnupg flex bison gperf build-essential zip curl \
    zlib1g-dev gcc-multilib g++-multilib libc6-dev-i386 lib32ncurses5-dev \
    x11proto-core-dev libx11-dev lib32z1-dev ccache libgl1-mesa-dev \
    libxml2-utils xsltproc unzip device-tree-compiler fish" \
    BUILDROOT_BUILDDEPS="libfile-which-perl sed make binutils gcc g++ bash \
    patch gzip bzip2 perl tar cpio python3 unzip rsync file bc libmpc3 \
    git repo texinfo pkg-config cmake tree udev dosfstools parted sudo" \
    TOOLS="genext2fs time wget liblz4-tool curl"

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get install -y \
      $KERNEL_BUILDDEPS \
      $BUILDROOT_BUILDDEPS \
      $TOOLS \
    && apt-get clean -y \
    && apt-get autoclean -y \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN git config --global --add safe.directory /skiffos
WORKDIR /skiffos
