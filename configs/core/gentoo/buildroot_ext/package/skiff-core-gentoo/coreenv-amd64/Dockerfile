FROM alpine:3.11 as builder

WORKDIR /gentoo

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUFFIX
# ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
ARG DIST="http://distfiles.gentoo.org/releases/amd64/autobuilds"
# ARG STAGE3PATH="stage3-amd64-systemd-20200722T214503Z.tar.xz"
ARG SIGNING_KEY="0xBB572E0E2D182910"

ENV GENTOO_ARCH ${ARCH}

RUN echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}" \
 && apk --no-cache add ca-certificates gnupg tar wget xz zsh \
 && STAGE3PATH="$(wget -O- "${DIST}/latest-stage3-amd64-systemd.txt" | tail -n 1 | cut -f 1 -d ' ')" \
 && echo "STAGE3PATH:" $STAGE3PATH \
 && STAGE3="$(basename ${STAGE3PATH})" \
 && wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" "${DIST}/${STAGE3PATH}.DIGESTS.asc" \
 && gpg --list-keys \
 && echo "honor-http-proxy" >> ~/.gnupg/dirmngr.conf \
 && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
 && gpg --keyserver hkps://keys.gentoo.org --recv-keys ${SIGNING_KEY} \
 && gpg --verify "${STAGE3}.DIGESTS.asc" \
 && awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS.asc | sha512sum -c \
 && tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner \
 && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
 && echo 'UTC' > etc/timezone \
 && rm ${STAGE3}.DIGESTS.asc ${STAGE3}.CONTENTS.gz ${STAGE3}

FROM scratch as stage3

WORKDIR /
COPY --from=builder /gentoo/ /
CMD ["/bin/bash"]

FROM stage3

# setup environment
ENV LANG C.UTF-8
ENV LC_ALL C.UTF-8
ENV container docker

COPY ./make.conf ./package.accept_keywords /etc/portage/
COPY ./package.use /etc/portage/package.use/01-standard
COPY ./world /var/lib/portage/world

# pass 1: base build env
# pass 2: update packages
# be failure tolerant here. we can deal with it later.
RUN \
  emerge-webrsync && \
  eselect profile set "default/linux/amd64/17.1/systemd" && \
  emerge --oneshot --nodeps portage && \
  emerge --oneshot --with-bdeps=y --update portage && \
  (emerge -uDU --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world || true) && \
  (emerge -uDU --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world || true) && \
  rm -rf /var/cache/distfiles/* /etc/xdg/autostart/* /var/db/repos/gentoo

# Create the user which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN groupadd sudo && \
  useradd \
  -G audio,dialout,sudo \
  core && \
  mkdir -p /home/core/ && \
  chown core:core /home/core && \
  echo "core    ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers


ADD ./system-auth /etc/pam.d/system-auth
RUN \
  systemctl set-default graphical.target && \
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
