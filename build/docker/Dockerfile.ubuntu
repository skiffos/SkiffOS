FROM ubuntu:latest
RUN apt update && \
    apt install -y build-essential \
    git gcc wget curl musl-dev file \
    perl python rsync bc patch unzip cpio
RUN adduser --gecos "Buildroot" --disabled-login --uid 1000 buildroot && \
    mkdir -p /home/buildroot && chown buildroot:buildroot /home/buildroot
USER buildroot
WORKDIR /home/buildroot
