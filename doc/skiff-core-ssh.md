# Dual SSH Daemon Setup

This guide explains how to configure separate SSH daemons for the SkiffOS host system and containers. Example use cases:

- The normal SSH for SkiffOS with skiff/core enabled maps "root" to go to the root within the "host system" and "core" to go to the core container. Running a ssh daemon in the container enables sshing to root within the container.
- If we want to remove a layer of indirection and have better performance with "scp" or "rsync" or X11 forwarding
- If we want to run specific pam rules for ssh and sshd_config within the container
- If we trust the hardening / security of the ssh daemon within the container more than the buildroot version

## Overview

By default, SkiffOS runs an SSH daemon on port 22 that provides access to the host system. However, in some deployment scenarios, you may want to:

- Make containers the "primary" access point for users
- Maintain emergency access to the host system
- Reduce complexity for team members unfamiliar with the host/container distinction

The solution is to run two SSH daemons:
1. **Container SSH daemon** on port 22 (default)
2. **Host SSH daemon** on an alternate port (e.g., 1920)

### Use Case Example

A company deploying Raspberry Pi devices with NixOS containers wants:
- `ssh root@device` → connects to NixOS container as root (primary system)
- `ssh -p 1920 root@device` → connects to SkiffOS host (emergency access)

This allows most users to interact only with the container, while administrators can still access the underlying host system when needed for troubleshooting, updates, or recovery.

## Host SSH Configuration

To configure the SkiffOS host SSH daemon to run on an alternate port:

### Step 1: Create SSH Config Override

Create the file `overrides/root_overlay/etc/ssh/sshd_config` with the following content:

```
# SkiffOS Host SSH Configuration
# Modified to run on alternate port to allow container SSH on port 22

# Change the default port
Port 1920

# Standard security settings
PermitRootLogin prohibit-password
PasswordAuthentication yes
UsePAM no
PrintMotd no

# Allow client to pass COLORTERM
AcceptEnv COLORTERM

# Subsystem for SFTP
Subsystem	sftp	/usr/libexec/sftp-server
```

### Step 2: Rebuild the Image

After creating the override file:

```bash
make compile
```

The host SSH daemon will now run on port 1920 instead of port 22.

### Connecting to Host

```bash
# Connect to SkiffOS host system
ssh -p 1920 root@device-ip-address
```

## Container SSH Configuration

Configure your container to run an SSH daemon on the default port 22. The configuration varies by distribution.

### Debian/Ubuntu Containers

For Debian-based containers in `/mnt/persist/skiff/core/config.yaml`:

```yaml
containers:
  core:
    image: skiffos/skiff-core-debian:latest
    ports:
      - "22:22"
    privileged: true
    capAdd:
      - SYS_ADMIN
```

Inside the container, install and enable SSH:

```bash
# Enter the container
docker exec -it core bash

# Install OpenSSH server
apt-get update
apt-get install -y openssh-server

# Enable and start SSH
systemctl enable ssh
systemctl start ssh

# Configure root login (if needed)
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart ssh
```

### NixOS Containers

For NixOS containers, add SSH configuration to your NixOS configuration file:

```nix
{ config, pkgs, ... }:

{
  # Enable SSH daemon
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  # Open firewall for SSH
  networking.firewall.allowedTCPPorts = [ 22 ];
}
```

Update your container config in `/mnt/persist/skiff/core/config.yaml`:

```yaml
containers:
  core:
    image: skiffos/docker-nixos:latest
    ports:
      - "22:22"
    privileged: true
    capAdd:
      - SYS_ADMIN
```

### Alpine Containers

For Alpine-based containers:

```yaml
containers:
  core:
    image: alpine:latest
    ports:
      - "22:22"
    privileged: true
    capAdd:
      - SYS_ADMIN
```

Inside the container:

```bash
# Enter the container
docker exec -it core sh

# Install OpenSSH
apk add openssh

# Generate host keys
ssh-keygen -A

# Configure root login
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config

# Start SSH daemon
rc-update add sshd default
rc-service sshd start
```

### Fedora Containers

For Fedora-based containers:

```yaml
containers:
  core:
    image: fedora:latest
    ports:
      - "22:22"
    privileged: true
    capAdd:
      - SYS_ADMIN
```

Inside the container:

```bash
# Enter the container
docker exec -it core bash

# Install OpenSSH server
dnf install -y openssh-server

# Enable and start SSH
systemctl enable sshd
systemctl start sshd

# Configure root login (if needed)
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
systemctl restart sshd
```

## SSH Key Management

To share SSH keys between the host and containers, you can use a symlink approach.

### Host SSH Keys Location

SkiffOS loads SSH public keys from:
- `/etc/skiff/authorized_keys` (from the image)
- `/mnt/persist/skiff/keys/` (from persist partition)

### Sharing Keys with Containers

#### Option 1: Symlink in Container

Create a symlink from the container's SSH authorized_keys to the host keys location:

```bash
# Inside the container
mkdir -p /root/.ssh
ln -sf /mnt/persist/skiff/keys/* /root/.ssh/authorized_keys
# Or copy the keys
cat /mnt/persist/skiff/keys/*.pub > /root/.ssh/authorized_keys
chmod 600 /root/.ssh/authorized_keys
```

#### Option 2: Mount Keys Directory

Add a mount in your container configuration:

```yaml
containers:
  core:
    image: skiffos/skiff-core-debian:latest
    ports:
      - "22:22"
    mounts:
      - /mnt/persist/skiff/keys:/etc/skiff/keys:ro
```

Then configure the container to read keys from `/etc/skiff/keys`.

#### Option 3: NixOS Configuration

For NixOS containers, add to your configuration:

```nix
{ config, pkgs, ... }:

{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PasswordAuthentication = false;
    };
  };

  # Read SSH keys from mounted directory
  users.users.root.openssh.authorizedKeys.keyFiles = [
    /mnt/persist/skiff/keys
  ];
}
```

Or use a startup script to copy keys:

```nix
systemd.services.copy-ssh-keys = {
  description = "Copy SSH keys from host";
  wantedBy = [ "multi-user.target" ];
  before = [ "sshd.service" ];
  script = ''
    mkdir -p /root/.ssh
    if [ -d /mnt/persist/skiff/keys ]; then
      cat /mnt/persist/skiff/keys/*.pub > /root/.ssh/authorized_keys
      chmod 600 /root/.ssh/authorized_keys
    fi
  '';
  serviceConfig = {
    Type = "oneshot";
  };
};
```

## Network Considerations

### Port Mapping

When running container SSH on port 22, ensure the port mapping is correct in your container configuration:

```yaml
containers:
  core:
    ports:
      - "22:22"  # Maps host port 22 to container port 22
```

### Firewall Rules

If you're using a firewall, ensure both ports are allowed:

```bash
# Allow host SSH port (if using firewall)
iptables -A INPUT -p tcp --dport 1920 -j ACCEPT

# Allow container SSH port
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
```

For NetworkManager-based firewall configurations, create:

`overrides/root_overlay/etc/NetworkManager/conf.d/99-firewall.conf`:

```
[main]
# Add firewall rules if needed
```

### Container Network Mode

For SSH to work correctly, the container needs network access. The default `bridge` network mode or `host` network mode both work:

```yaml
containers:
  core:
    networkMode: bridge  # Default, provides isolated network
    # or
    networkMode: host    # Container shares host network stack
```

## Troubleshooting

### Can't Connect to Container SSH

1. **Check if SSH is running in the container:**
   ```bash
   docker exec core systemctl status sshd
   # or for Alpine
   docker exec core rc-service sshd status
   ```

2. **Verify port mapping:**
   ```bash
   docker port core
   ```

3. **Check container logs:**
   ```bash
   docker logs core
   ```

4. **Test from host:**
   ```bash
   ssh -p 22 root@localhost
   ```

### Can't Connect to Host SSH

1. **Check if host SSH is running:**
   ```bash
   systemctl status sshd
   ```

2. **Verify the port:**
   ```bash
   netstat -tlnp | grep 1920
   # or
   ss -tlnp | grep 1920
   ```

3. **Check host SSH logs:**
   ```bash
   journalctl -u sshd -f
   ```

### SSH Keys Not Working

1. **Verify keys are present:**
   ```bash
   # On host
   ls -la /mnt/persist/skiff/keys/
   
   # In container
   docker exec core ls -la /root/.ssh/
   docker exec core cat /root/.ssh/authorized_keys
   ```

2. **Check permissions:**
   ```bash
   # authorized_keys should be 600
   # .ssh directory should be 700
   docker exec core chmod 700 /root/.ssh
   docker exec core chmod 600 /root/.ssh/authorized_keys
   ```

3. **Check SSH daemon logs:**
   ```bash
   # In container
   docker exec core journalctl -u sshd -f
   # or check /var/log/auth.log
   docker exec core tail -f /var/log/auth.log
   ```

### Port Already in Use

If port 22 or 1920 is already in use:

1. **Check what's using the port:**
   ```bash
   lsof -i :22
   lsof -i :1920
   ```

2. **Choose a different port** in the SSH configuration.

## Complete Example Setup

Here's a complete example for a Raspberry Pi 4 with Debian container:

### 1. Host Configuration

`overrides/root_overlay/etc/ssh/sshd_config`:
```
Port 1920
PermitRootLogin prohibit-password
PasswordAuthentication yes
UsePAM no
PrintMotd no
AcceptEnv COLORTERM
Subsystem	sftp	/usr/libexec/sftp-server
```

### 2. Add SSH Keys

```bash
cp ~/.ssh/id_ed25519.pub overrides/root_overlay/etc/skiff/authorized_keys/admin.pub
```

### 3. Container Configuration

`overrides/root_overlay/opt/skiff/coreenv/defconfig.yaml`:
```yaml
containers:
  core:
    image: skiffos/skiff-core-debian:latest
    hostname: mydevice
    ports:
      - "22:22"
    mounts:
      - /mnt/persist/skiff/keys:/mnt/skiff-keys:ro
    privileged: true
    capAdd:
      - SYS_ADMIN
```

### 4. Container Startup Script

Create `overrides/root_overlay/opt/skiff/coreenv/defconfig.sh`:
```bash
#!/bin/bash
# Wait for container to be ready
sleep 5

# Setup SSH in container
docker exec core bash -c '
  apt-get update
  apt-get install -y openssh-server
  mkdir -p /root/.ssh
  cat /mnt/skiff-keys/*.pub > /root/.ssh/authorized_keys
  chmod 700 /root/.ssh
  chmod 600 /root/.ssh/authorized_keys
  systemctl enable ssh
  systemctl start ssh
'
```

Make it executable:
```bash
chmod +x overrides/root_overlay/opt/skiff/coreenv/defconfig.sh
```

### 5. Build and Deploy

```bash
# Configure
export SKIFF_CONFIG=pi/4

# Compile
make compile

# Flash to SD card
# ... flash image to SD card ...

# Boot device and connect
ssh root@device-ip           # Connects to container
ssh -p 1920 root@device-ip   # Connects to host
```

## Best Practices

1. **Always maintain host access**: Keep the host SSH daemon accessible on an alternate port for emergency access and troubleshooting.

2. **Use key-based authentication**: Disable password authentication for better security, especially on the container SSH.

3. **Document the setup**: Ensure your team knows which port goes to which system.

4. **Test emergency access**: Regularly verify you can still access the host system in case the container breaks.

5. **Backup configurations**: Keep your SSH configurations in version control as part of your SkiffOS overlay.

6. **Monitor both SSH daemons**: Set up logging and monitoring for both the host and container SSH services.

7. **Use consistent key management**: Decide on a key management strategy (symlink, copy, or mount) and document it.

## Security Considerations

- **Minimize attack surface**: Only expose necessary ports and services.
- **Use strong authentication**: Prefer key-based authentication over passwords.
- **Keep systems updated**: Regularly update both the host and container SSH packages.
- **Monitor access logs**: Review SSH logs regularly for unauthorized access attempts.
- **Use fail2ban**: Consider installing fail2ban on both host and container to prevent brute-force attacks.
- **Restrict root login**: Consider creating non-root users for day-to-day access.

## Related Documentation

- [README.md](../README.md) - General SkiffOS setup and configuration
- [doc/configuring.md](./configuring.md) - Configuration package system
- [SSH Keys section in README](../README.md#ssh-keys) - SSH key management basics
