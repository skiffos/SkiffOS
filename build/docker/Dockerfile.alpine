FROM alpine:edge
RUN apk --update upgrade
RUN apk add make git bash ncurses gcc wget curl \
    musl-dev file g++ perl python rsync bc patch \
    libintl libtool alpine-sdk gettext
RUN adduser -D -u 1000 -g 1001 buildroot && \
    mkdir -p /home/buildroot && chown buildroot:buildroot /home/buildroot
USER buildroot
WORKDIR /home/buildroot
