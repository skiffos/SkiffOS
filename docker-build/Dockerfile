FROM ubuntu:latest
RUN apt update && \
    apt install -y build-essential \
    git gcc wget curl musl-dev file locales \
    perl python rsync bc patch unzip cpio
RUN locale-gen en_US.UTF-8 && update-locale LC_ALL=en_US.UTF-8 LANG=en_US.UTF-8
RUN adduser --gecos "Buildroot" --disabled-login --uid 1000 buildroot && \
    mkdir -p /home/buildroot && chown buildroot:buildroot /home/buildroot
USER buildroot
WORKDIR /home/buildroot
