# Portainer on SkiffOS

[Portainer] can be used to manage SkiffOS hosts with a user-friendly UI.

Enabling the "apps/portainer" layer in the SKIFF_CONFIG will start the server
and agent as containers at runtime, configured to run the UI on port 9443.

## Server

To setup the server on an existing system, ssh to "root" and run:

```sh
# Create the storage volume.
docker volume create portainer_data
# Create the Portainer Server container.
docker run -d -p 8000:8000 -p 9443:9443 --name portainer \
    --restart=always \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v portainer_data:/data \
    cr.portainer.io/portainer/portainer-ce:2.9.3
```

You can then access the UI at the device IP, port 9443, with a browser.

For example, using the device IP: https://my-device-ip:9443

The server uses a self-signed cert and will likely cause a security warning.

## Agent

To setup the agent on an existing system, ssh to "root" and run:

```sh
docker run -d --restart=always \
  -p 9001:9001 \
  --name portainer_agent \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  cr.portainer.io/portainer/agent:2.9.3
```

You can also include the agent in the image to be automatically launched at
startup by adding the "apps/portainer" layer to your SKIFF_CONFIG.

[Portainer]: https://portainer.io
