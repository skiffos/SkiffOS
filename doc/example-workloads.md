# Example Workloads

These are some examples to try out.

Note: this requires SKIFF_CONFIG=apps/docker at minimum.

With Skiff Core - SKIFF_CONFIG=skiff/core - you can simply run "su - core" to
switch into the containerized environment (with the default configs).

## System Tools with Alpine

Note: with Skiff Core - `SKIFF_CONFIG=skiff/core` - you can run "su - core" to
switch into the containerized environment (with the default configs).

Alpine provides a lightweight environment with a package manager (apk) to
install developer tools on-demand. This command will execute a persistent
container named "work" which you can execute a shell inside to interact with.
This workflow is similar to how Skiff Core drops SSH sessions into Docker
containers as an optional feature.

```bash
docker run \
	--name=work -d \
    --pid=host --uts=host --net=host \
    --privileged \
    -v /:/root-fs -v /dev:/dev \
    --privileged \
    alpine:edge \
    bin/sleep 99999
    
# Execute a shell in the container.
docker exec -it work sh

# Update the packages.
apk upgrade --update

# Add a package.
apk add vim
apk add alpine-sdk # adds compilers
```

Some useful tools to try:

 - htop: interactive process manager similar to top
 - atop: shows CPU statistics and process information as well as summaries of
   network interface load.
 - bwm-ng: simple lightweight UI to show rx/tx and total bandwidth of all interfaces.
 - bmon: detailed UI, shows all details of any network errors experienced and
   current bandwidth on all interfaces.
 - nload: shows incoming and outgoing network load.
 - nethogs: shows what processes are using network traffic.

## System Performance Monitoring with Glances

System performance monitoring and benchmarking is easy with the glances tool.

The below command can be executed after sshing to the "root" user to start the
performance monitoring UI on port 61208 on the device (for the ARM
architecture):

```bash
docker run \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  --pid=host --net=host \
  --restart=always \
  --name=glances \
  --detach=true \
  --privileged \
  paralin/glances-arm:latest glances -w
```

## Container Performance Monitoring with Cadvisor

System and container performance monitoring and benchmarking is easy with the cadvisor tool.

The below command can be executed after sshing to the "root" user to start the performance monitoring UI on port 8080 on the device:

```bash
docker run \
 --volume=/var/run:/var/run:rw \
 --volume=/sys:/sys:ro \
 --volume=/var/lib/docker/:/var/lib/docker:ro \
 --publish=8080:8080 \
 --detach=true \
 --name=cadvisor \
 braingamer/cadvisor-arm:latest
```

## Install Docker inside Core

You can install Docker inside the core environment, and systemd is running, so
you can enable it to correctly auto-start when you first connect.

```bash
ssh core@my-skiff-host
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io
sudo systemctl enable --now docker
sudo docker ps
```

This is "docker inside docker!"
