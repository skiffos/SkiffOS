## Skiff vs. booting directly to the userspace

Skiff loads a small image containing the kernel and core system into RAM at
boot-time. This ensures that the system will always boot up into a consistent
state, ideal for embedded and mission-critical environments. Sudden failure of
the storage drive does not break the system, as the core OS runs from memory.

As a modular configuration package manager for the industry-standard
[Buildroot](http://buildroot.org) embedded Linux tool, Skiff allows for a
consistent developer experience and application execution environment across any
compute platform. The compact nature of the system creates a minimal attack
surface for security.

Skiff decouples the core OS (kernel, bootup process, virtualization) from the
userspace. This is optimal for containerized host systems as the Skiff portion
can be updated independently from the userspace and easily rolled back. The
environments inside the containers can be upgraded without fear of bricking the
boot-up process. Because the system upgrade becomes an atomic operation, testing
and quality assurance can be greatly accelerated.

Traditionally, vendors will supply pre-installed GNU/Linux distributions on
embedded development boards. Variance in these images creates a significant pain
point in embedded Linux development, and the practice of "imaging" an entire
drive is a significant time bottleneck and inhibitor of proper backup practices.
Finally, there's no clear way to keep multiple development devices in sync or
maintaining the same configuration changes with the traditional approach.
