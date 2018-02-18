FROM ubuntu:latest
RUN apt update && \
    apt install -y build-essential \
    git gcc wget curl musl-dev file locales \
    perl python rsync bc patch unzip cpio
RUN localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 && \
    locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN adduser --gecos "Buildroot" --disabled-login --uid 1000 buildroot && \
    mkdir -p /home/buildroot && chown buildroot:buildroot /home/buildroot
USER buildroot
ENV LANG en_US.UTF-8
WORKDIR /home/buildroot
