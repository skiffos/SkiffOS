# See: https://github.com/gentoo/gentoo-docker-images/blob/master/stage3.Dockerfile
ARG BOOTSTRAP

FROM ${BOOTSTRAP:-alpine:edge} AS downloader
# FROM ${BOOTSTRAP:-quay.io/skiffos/alpine:latest} as downloader

WORKDIR /gentoo

ARG ARCH=amd64
ARG MICROARCH=amd64
ARG SUBPROFILE=systemd
ARG SUFFIX="-systemd"
ARG DIST="https://ftp-osl.osuosl.org/pub/gentoo/releases/${ARCH}/autobuilds"
ARG SIGNING_KEY="0xBB572E0E2D182910"

ADD ./overrides.sh /

RUN apk --no-cache --upgrade add ca-certificates gnupg tar wget xz

RUN source /overrides.sh \
    && echo "Fetching Gentoo signing key ${SIGNING_KEY}" \
    && gpg --list-keys \
    && echo "honor-http-proxy" >> ~/.gnupg/dirmngr.conf \
    && echo "disable-ipv6" >> ~/.gnupg/dirmngr.conf \
    && gpg --keyserver hkps://keys.gentoo.org --recv-keys ${SIGNING_KEY}

RUN source /overrides.sh \
 && echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}" \
 && STAGE3PATH="$(wget -O- "${DIST}/latest-stage3-${MICROARCH}${SUFFIX}.txt" | grep -E '^[0-9]+.*\.tar\.xz' | awk '{print $1}')" \
 && echo "STAGE3PATH:" $STAGE3PATH \
 && STAGE3="$(basename ${STAGE3PATH})" \
    && wget "${DIST}/${STAGE3PATH}.asc" "${DIST}/${STAGE3PATH}.DIGESTS" \
    && wget -q "${DIST}/${STAGE3PATH}" "${DIST}/${STAGE3PATH}.CONTENTS.gz" \
 && gpg --verify "${STAGE3}.asc" \
 && awk '/# SHA512 HASH/{getline; print}' ${STAGE3}.DIGESTS | sha512sum -c \
 && tar xpf "${STAGE3}" --xattrs-include='*.*' --numeric-owner \
 && ( sed -i -e 's/#rc_sys=""/rc_sys="docker"/g' etc/rc.conf 2>/dev/null || true ) \
 && echo 'UTC' > etc/timezone \
 && rm ${STAGE3}.asc ${STAGE3}.DIGESTS ${STAGE3}.CONTENTS.gz ${STAGE3}

FROM scratch AS stage3

WORKDIR /
COPY --from=downloader /gentoo/ /
CMD ["/bin/bash"]

FROM stage3 AS stage4

# setup environment
ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  container=docker

# we don't have Git yet, so download a gentoo tarball.
RUN emerge-webrsync

# ensure git is merged so we can use Git for portage
RUN emerge --oneshot --quiet-build y --with-bdeps=y --backtrack=30 dev-vcs/git

# switch to git-based portage
COPY ./overrides.sh /gentoo-skiff-overrides.sh
RUN source /gentoo-skiff-overrides.sh; \
  PROFILES_DIR=/var/db/repos/gentoo/profiles/default; \
  PROFILE_DIR=$(find ${PROFILES_DIR}/linux/${ARCH} -maxdepth 1 -type d -name "[0-9]*" | sort -V | tail -n1)/${SUBPROFILE}; \
  PROFILE=default/${PROFILE_DIR#"${PROFILES_DIR}/"}; \
  eselect profile set "${PROFILE}"; \
  touch /etc/portage/repos.conf

# add repos.conf and use git portage from now forward
COPY ./repos.conf /etc/portage/repos.conf
RUN rm -rf /var/db/repos/gentoo /etc/portage/package.use; \
    mkdir -p /etc/portage/package.{use,keywords}; \
    emerge --sync; \
    rm /gentoo-skiff-overrides.sh

# apply package keywords, use flags, etc
COPY ./make.conf /etc/portage/
COPY ./package.accept_keywords /etc/portage/package.accept_keywords/01-standard
COPY ./package.use /etc/portage/package.use/01-standard
COPY ./sysctl.conf /etc/sysctl.conf

# pass #1: base package set, system, remove tk and icu to fix circular deps
# be failure tolerant here. we can deal with it later.
# disable certain use flags that cause cycles
RUN \
  export USE="-tk -icu" && \
  emerge -1 portage && \
  emerge -1 gentoo-sources && \
  (emerge -uDU --quiet-build y --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @system || true)

# update gcc (not currently necessary)
# RUN gcc-config -l | grep "10." | cut -d[ -f2 | cut -d] -f1 | xargs gcc-config; \
#  source /etc/profile; \
#  emerge --oneshot --with-bdeps=y sys-devel/libtool

# pass #2: world set from the skiff core world file
COPY ./world /var/lib/portage/world
RUN (emerge -uDU --quiet-build y --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world || true)

# pass #3: ensure that everything is up to date & this command works without errors
# sometimes, emerge requires 2 passes to pick up everything
RUN emerge --update --newuse --deep --backtrack=50 @world

# pass #4: clean any outdated / not needed dependencies
# minimize image size
RUN emerge --unmerge gentoo-sources; \
   (emerge --depclean || true); \
   rm -rf /var/cache/distfiles/* \
   /var/log/* /var/tmp/* /usr/src/* \
   /etc/xdg/autostart/* /var/db/repos/gentoo || true

FROM scratch

COPY --from=stage4 / /

ENV container docker

# Create the user which will be the usual userspace account
# Also allow core to run stuff as sudo without a password.
RUN \
  useradd \
  -G users,audio,dialout,systemd-journal \
  -s /bin/bash \
  core && \
  mkdir -p /home/core/ && \
  chown core:core /home/core && \
  printf "# skiff core build user\ncore    ALL=(ALL) NOPASSWD: ALL\n" > /etc/sudoers.d/10-skiff-core && \
  chmod 0400 /etc/sudoers.d/10-skiff-core && \
  visudo -c -f /etc/sudoers.d/10-skiff-core

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
