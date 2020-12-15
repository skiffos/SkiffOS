FROM alpine:3.11 as builder

WORKDIR /gentoo

ARG ARCH=arm64
ARG DIST="http://distfiles.gentoo.org/releases/${ARCH}"
ARG STAGE3PATH="autobuilds/current-stage3-${ARCH}-systemd/stage3-${ARCH}-systemd-20201004T190540Z.tar.xz"
ARG SIGNING_KEY="13EBBDBEDE7A12775DFDB1BABB572E0E2D182910"

ENV GENTOO_ARCH ${ARCH}
ENV STAGE3PATH ${STAGE3PATH}
ADD ./overrides.sh /

RUN apk upgrade --update && \
    apk add ca-certificates gnupg tar wget xz
RUN source /overrides.sh \
 && echo "Building Gentoo Container image for ${ARCH} fetching from ${DIST}" \
 && echo "STAGE3PATH:" $STAGE3PATH \
 && STAGE3="$(basename ${STAGE3PATH})" \
 && wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" "${DIST}/${STAGE3PATH}.DIGESTS" \
 && tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner \
 && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
 && rm ${STAGE3}.DIGESTS ${STAGE3}.CONTENTS.gz ${STAGE3}

FROM scratch as stage3

WORKDIR /
COPY --from=builder /gentoo/ /
CMD ["/bin/bash"]

FROM stage3 as stage4

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV container docker

COPY ./make.conf ./package.accept_keywords /etc/portage/
ADD ./overrides.sh /gentoo-skiff-overrides.sh
COPY ./package.use /etc/portage/package.use/01-standard

# pass 1: base build env
# pass 2: update packages
# be failure tolerant here. we can deal with it later.
# disable certain use flags that cause cycles
RUN emerge-webrsync
RUN source /gentoo-skiff-overrides.sh; \
  sed -i -e "s#ARCH#${ARCH}#g" /etc/portage/package.accept_keywords; \
  eselect profile set "default/linux/${ARCH}/17.0/systemd"; \
  rm /gentoo-skiff-overrides.sh

RUN \
  export USE="-tk" && \
  (emerge --oneshot --nodeps portage || true) && \
  (emerge --oneshot --with-bdeps=y --update portage || true) && \
  (emerge -uDU --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world || true)

COPY ./world /var/lib/portage/world
RUN emerge -uDU --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world || true

# minimize image size
RUN rm -rf /var/cache/distfiles/* \
   /etc/xdg/autostart/* /var/db/repos/gentoo || true

FROM scratch

COPY --from=stage4 / /

ENV container docker

# Create the user which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
  useradd \
  -G users,audio,dialout \
  -s /bin/bash \
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

