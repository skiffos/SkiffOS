# See: https://github.com/gentoo/gentoo-docker-images/blob/master/stage3.Dockerfile
ARG BOOTSTRAP
# FROM ${BOOTSTRAP:-alpine:latest} as builder
FROM ${BOOTSTRAP:-quay.io/skiffos/alpine:latest} as builder

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
 && echo "Building Gentoo Container image for ${ARCH} ${SUFFIX} fetching from ${DIST}" \
 && STAGE3PATH="$(wget -O- "${DIST}/latest-stage3-${MICROARCH}${SUFFIX}.txt" | tail -n 1 | cut -f 1 -d ' ')" \
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

FROM stage3 as stage4

# setup environment
ENV LANG=C.UTF-8 \
  LC_ALL=C.UTF-8 \
  container=docker

# we don't have Git yet, so download a gentoo tarball.
RUN emerge-webrsync
# ensure git is merged, unconditionally, so we can use Git for portage
RUN emerge --oneshot --quiet-build y --with-bdeps=y --backtrack=30 dev-vcs/git
# switch to git-based portage
COPY ./overrides.sh /gentoo-skiff-overrides.sh
RUN source /gentoo-skiff-overrides.sh; \
  PROFILES_DIR=/var/db/repos/gentoo/profiles/default; \
  PROFILE_DIR=$(realpath ${PROFILES_DIR}/linux/${ARCH}/17.*/${SUBPROFILE} | sort | tail -n1); \
  PROFILE=default/${PROFILE_DIR#"${PROFILES_DIR}/"}; \
  eselect profile set "${PROFILE}"; \
  touch /etc/portage/repos.conf

# add repos.conf and use git portage from now forward
COPY ./repos.conf /etc/portage/repos.conf
RUN rm -rf /var/db/repos/gentoo/*; \
    mkdir -p /var/db/repos/localrepo-crossdev/{profiles,metadata}; \
    echo 'crossdev' > /var/db/repos/localrepo-crossdev/profiles/repo_name; \
    echo 'masters = gentoo' > /var/db/repos/localrepo-crossdev/metadata/layout.conf; \
    chown -R portage:portage /var/db/repos/localrepo-crossdev; \
    rm -rf /etc/portage/package.use || true; \
    mkdir -p /etc/portage/package.use; \
    emerge --sync

# apply package keywords, use flags, etc
COPY ./make.conf ./package.accept_keywords /etc/portage/
RUN \
  source /gentoo-skiff-overrides.sh; \
  sed -i -e "s#ARCH#${ARCH}#g" /etc/portage/package.accept_keywords; \
  mv /etc/portage/package.accept_keywords /etc/portage/package-accept.tmp; \
  mkdir -p /etc/portage/package.accept_keywords; \
  mv /etc/portage/package-accept.tmp /etc/portage/package.accept_keywords/01-standard; \
  rm /gentoo-skiff-overrides.sh
COPY ./package.use /etc/portage/package.use/01-standard

# pass #1: base package set, system, remove tk and icu to fix circular deps
# be failure tolerant here. we can deal with it later.
# disable certain use flags that cause cycles
# includes gcc 10
RUN \
  export USE="-tk -icu" && \
  (emerge -uDU --quiet-build y --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @system || true)

# update to gcc 10
RUN gcc-config -l | grep "10." | cut -d[ -f2 | cut -d] -f1 | xargs gcc-config; \
  source /etc/profile; \
  emerge --oneshot --with-bdeps=y sys-devel/libtool

# pass #2: world set from the skiff core world file
COPY ./world /var/lib/portage/world
RUN (emerge -uDU --quiet-build y --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world || true) && \
    (emerge --depclean || true)

# pass #3: ensure that everything is up to date & this command works without errors
# sometimes, emerge requires 2 passes to pick up everything
RUN emerge -uDU --with-bdeps=y --keep-going --autounmask-write --autounmask-backtrack=y --backtrack=50 @world

# minimize image size
RUN rm -rf /var/cache/distfiles/* \
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

# mask any remaining systemd services
RUN \
  rm /etc/sysctl.conf && touch /etc/sysctl.conf; \
  systemctl mask tmp.mount 

WORKDIR /
ENTRYPOINT ["/lib/systemd/systemd"]
