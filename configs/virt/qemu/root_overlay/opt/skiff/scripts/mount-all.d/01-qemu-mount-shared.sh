mkdir -p /mnt/shared
mount -t 9p -o trans=virtio host0 /mnt/shared
