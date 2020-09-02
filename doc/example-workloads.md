# Example Workloads

These are some examples to try out.

Note: this requires SKIFF_CONFIG=apps/docker at minimum.

With Skiff Core - SKIFF_CONFIG=skiff/core - you can simply run "su - core" to
switch into the containerized environment (with the default configs).

### System Performance Monitoring with Glances

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

### Container Performance Monitoring with Cadvisor

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
