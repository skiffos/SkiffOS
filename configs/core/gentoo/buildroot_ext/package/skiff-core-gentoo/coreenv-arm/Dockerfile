FROM alpine:3.11 as builder

WORKDIR /gentoo

# ARG ARCH=amd64
ARG ARCH=arm
# ARG MICROARCH=amd64
ARG MICROARCH=arm
ARG SUFFIX
# ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
ARG DIST="http://distfiles.gentoo.org/releases/arm/autobuilds"
ARG SIGNING_KEY="13EBBDBEDE7A12775DFDB1BABB572E0E2D182910"

ENV GENTOO_ARCH ${ARCH}

RUN echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}" \
 && apk --no-cache add ca-certificates gnupg tar wget xz \
 && STAGE3PATH="20200509T210605Z/stage3-armv7a_hardfp-20200509T210605Z.tar.xz" \
 && echo "STAGE3PATH:" $STAGE3PATH \
 && STAGE3="$(basename ${STAGE3PATH})" \
 && wget "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" "${DIST}/${STAGE3PATH}.DIGESTS" \
 && tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner \
 && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
 && rm ${STAGE3}.DIGESTS ${STAGE3}.CONTENTS.gz ${STAGE3}

FROM scratch as stage3

WORKDIR /
COPY --from=builder /gentoo/ /
CMD ["/bin/bash"]

FROM stage3

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV TERM xterm
ENV container docker

# COPY ./repos.conf /usr/share/portage/config/repos.conf
# COPY ./make.conf /etc/portage/
RUN emerge-webrsync

# pass 1: base build env
COPY ./make.conf ./package.accept_keywords ./package.license /etc/portage/
RUN \
  emerge --oneshot --nodeps portage && \
  emerge --oneshot --with-bdeps=y --update portage

# pass 2: update packages
COPY ./package.use /etc/portage/package.use/01-standard
RUN \
  (emerge -uDU --with-bdeps=y --autounmask-write --autounmask-backtrack=y @world || true) && \
  (emerge --autounmask-write sudo app-portage/gentoolkit || true) && \
  rm -rf /var/cache/distfiles/* /etc/xdg/autostart/*

RUN (emerge -uDU --with-bdeps=y --autounmask-write --keep-going @world || true) && \
    (emerge --autounmask-write \
      sudo app-portage/gentoolkit dev-vcs/git app-portage/repoman || true) && \
    rm -rf /var/cache/distfiles/* /etc/xdg/autostart/*

RUN (emerge --autounmask-write zsh || true); \
  rm -rf /var/cache/distfiles/* /etc/xdg/autostart/*

# merge later
COPY ./world /var/lib/portage/world
#RUN (emerge -uDU --with-bdeps=y --keep-going --autounmask-write @world || true); \
#  rm -rf /var/cache/distfiles/* /etc/xdg/autostart/*

# Create the user which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN groupadd sudo && \
  useradd \
  -G users,audio,dialout,sudo \
  -s /bin/zsh \
  core && \
  mkdir -p /home/core/ && \
  chown core:core /home/core && \
  echo "core    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ADD ./system-auth /etc/pam.d/system-auth
RUN \
  systemctl mask tmp.mount && \
  find /etc/systemd/system \
  /lib/systemd/system \
  \( -path '*.wants/*' \
  -name '*swapon*' \
  -or -name '*ntpd*' \
  -or -name '*resolved*' \
  -or -name '*persist-resize*' \
  -or -name '*remount-fs*' \
  -or -name '*getty*' \
  -or -name '*systemd-sysctl*' \
  -or -name '*.mount' \
  -or -name '*remote-fs*' \) \
  -exec echo \{} \; \
  -exec rm \{} \;

WORKDIR /home/core
ENTRYPOINT ["/lib/systemd/systemd"]

