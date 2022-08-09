#define _GNU_SOURCE
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <libgen.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <ftw.h>

#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

#include <linux/loop.h>

#ifndef MS_MOVE
#define MS_MOVE 8192
#endif

#ifndef MNT_DETACH
#define MNT_DETACH 0x00000002
#endif

#define MAX_RESIZE2FS_DEV_LEN 256

// To wait for a file to exist before starting:
// #define WAIT_EXISTS "/dev/mmcblk0"

// To mount / to /mnt/persist:
// #define ROOT_AS_PERSIST

// To mount / to /mnt/boot
// #define ROOT_AS_BOOT

// To mount a path or device to /mnt/boot before the rootfs.
// #define MOUNT_BOOT "/dev/mmcblk0p1"

// To mount the path using a bind mount.
// #define MOUNT_BOOT_BIND

// To enable reading resize2fs.conf
// #define RESIZE2FS

// Controls the maximum memory usage of the tmpfs /.
// Used as the upper layer of the overlayfs.
#ifndef MUTABLE_OVERLAY_SIZE
#define MUTABLE_OVERLAY_SIZE "1G"
#endif

// To disable the moving mountpoint to /
// #define NO_MOVE_MOUNTPOINT_ROOT

// To disable mounting /proc into the chroot
// #define NO_MOUNT_PROC

// To disable mounting /sys into the chroot
// #define NO_MOUNT_SYS

// To inherit /mnt in the chroot
// #define BIND_ROOT_MNT

// To disable chroot before running init
// #define NO_CHROOT_TARGET

// Override SKIFF_INIT_PROC to control the init process in the chroot
#ifndef SKIFF_INIT_PROC
#define SKIFF_INIT_PROC "/lib/systemd/systemd"
#endif

// To write a PID file for the init proc.
// #define WRITE_SKIFF_INIT_PID

#ifndef SKIFF_INIT_PID
#define SKIFF_INIT_PID "/run/skiff-init/skiff-init.pid"
#endif

#ifndef SKIFF_INIT_FILE
#define SKIFF_INIT_FILE "/boot/rootfs.squashfs"
#endif

const char *init_proc = SKIFF_INIT_PROC;
const char *init_pid_path = SKIFF_INIT_PID;

FILE *logfd;
const char *pid1_log = "/dev/kmsg";
const char *squashfs_file = SKIFF_INIT_FILE;

const char *resize2fs_path = "/boot/skiff-init/resize2fs";
const char *resize2fs_conf = "/boot/skiff-init/resize2fs.conf";

#ifndef SKIFF_MOUNTS_DIR
#define SKIFF_MOUNTS_DIR "/skiff-overlays"
#define SKIFF_MOUNTPOINT SKIFF_MOUNTS_DIR "/system"
#endif

const char *root_dir = SKIFF_MOUNTS_DIR;
const char *mountpoint = SKIFF_MOUNTPOINT;
const char *dev_mnt = SKIFF_MOUNTPOINT "/dev";
const char *proc_mnt = SKIFF_MOUNTPOINT "/proc";
const char *run_mnt = SKIFF_MOUNTPOINT "/run";
const char *sys_mnt = SKIFF_MOUNTPOINT "/sys";
const char *mnt_mnt = SKIFF_MOUNTPOINT "/mnt";
const char *boot_mnt = SKIFF_MOUNTPOINT "/mnt/boot";
const char *persist_mnt = SKIFF_MOUNTPOINT "/mnt/persist";
const char *boot_parent_mnt = "/mnt/boot";
const char *persist_parent_mnt = "/mnt/persist";
const char *image_mountpoint = SKIFF_MOUNTS_DIR "/image";
const char *overlay_tmp_mountpoint = SKIFF_MOUNTS_DIR "/system-tmp";

#ifdef MOUNT_BOOT
#ifndef MOUNT_BOOT_FSTYPE
#define MOUNT_BOOT_FSTYPE "vfat"
#endif
const char* mount_boot_device = MOUNT_BOOT;
const char* mount_boot_fstype = MOUNT_BOOT_FSTYPE;
#endif

#ifdef WAIT_EXISTS
const char* wait_exists_path = WAIT_EXISTS;
#endif

// Set BIND_HOST_PATHS to a space-separated list of paths to bind mount:
// Each path should be host-path:target-path
// i.e. /mydir:/my-target-dir /init:/bin/wslpath
#ifndef BIND_HOST_PATHS
#define BIND_HOST_PATHS ""
#endif

char *loopdev_find_unused();
int loopdev_setup_device(const char *file, uint64_t offset, const char *device);
void write_skiff_init_pid(pid_t pid);
void do_bind_host_paths(void);

int main(int argc, char *argv[]) {
  int res = 0;
  logfd = stderr;
  int closeLogFd = 0;
  struct stat st = {0};

  // log to uart, mount /dev
  if (getpid() == 1) {
    // mkdir -p /dev
    if (stat("/dev", &st) == -1) {
      mkdir("/dev", 0755);
    }

    // mount devtmpfs: if not already mounted
    if (mount("devtmpfs", "/dev", "devtmpfs", 0, NULL) != 0) {
      res = errno;
      fprintf(logfd,
              "SkiffOS init: failed to mount root /dev devtmpfs: (%d) %s\n",
              res, strerror(res));
      res = 0; // ignore for now
    }

    logfd = fopen(pid1_log, "w");
    if (logfd == 0) {
      fprintf(logfd, "Failed to open %s as PID 1: %s\n", pid1_log,
              strerror(errno));
      logfd = stderr;
    } else {
      setbuf(logfd, NULL);
      closeLogFd = 1;
    }

    fprintf(logfd, "SkiffOS init: mounted devtmpfs to /dev\n");
  }

  // clear the init PID early
#ifdef WRITE_SKIFF_INIT_PID
  if (stat(init_pid_path, &st) == 0) {
    unlink(init_pid_path);
  }
#endif

  // mkdir -p ${root_dir}
  if (stat(root_dir, &st) == -1) {
    mkdir(root_dir, 0700);
  }

  if (stat("/proc", &st) == -1) {
    mkdir("/proc", 0555);
  }

  if (stat("/mnt", &st) == -1) {
    mkdir("/mnt", 0755);
  }

  // if ! mountpoint /proc; mount -t proc proc /proc; fi
  if (stat("/proc/stat", &st) != 0) {
    if (mount("proc", "/proc", "proc", 0, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS init: failed to mount /proc: (%d) %s\n", res,
              strerror(res));
    }
  }


  // mount /etc/mtab
  if (stat("/etc", &st) == -1) {
    mkdir("/etc", 0755);
  }
  if (stat("/etc/mtab", &st) != 0) {
    /*
      int mt = open("/etc/mtab", O_WRONLY|O_CREAT|O_NOCTTY, 0777);
      if (mt != -1) {
      close(mt);
      }
    */

    if (symlink("/proc/mounts", "/etc/mtab") != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS: failed to create mtab symlink: (%d) %s\n", res,
              strerror(res));
      res = 0;
    }
  }

#ifdef WAIT_EXISTS
  int waiti = 0;
  while (stat(wait_exists_path, &st) != 0) {
    if (++waiti >= 10) {
      return 1;
    }

    fprintf(logfd, "SkiffOS: waiting for path to exist (x%d): %s\n", waiti, wait_exists_path);
    sleep(1.0);
  }
#endif

  // resize filesystems if necessary
  // it is assumed that root= was set to the "persist" partition and that the
  // boot data is stored in /boot. this may be changed later to support more
  // exotic setups.
#ifdef RESIZE2FS
  if (stat(resize2fs_path, &st) == 0 && stat(resize2fs_conf, &st) == 0) {
    // read the path(s) to resize from the conf file.
    // all lines not starting with # are assumed to be paths to device files.
    // all lines must have a /dev prefix.
    FILE *r2conf = fopen(resize2fs_conf, "r");
    char *linebuf = (char *)malloc(MAX_RESIZE2FS_DEV_LEN * sizeof(char));
    while (fgets(linebuf, MAX_RESIZE2FS_DEV_LEN - 1, r2conf)) {
      linebuf[MAX_RESIZE2FS_DEV_LEN - 1] = 0;
      if (linebuf[0] == '#') {
        continue;
      }
      linebuf[strcspn(linebuf, "\n")] = 0;
      linebuf[strcspn(linebuf, " ")] = 0;
      if (strlen(linebuf) < 6) {
        fprintf(logfd, "SkiffOS resize2fs: %s: line too short: %s\n",
                resize2fs_conf, linebuf);
        continue;
      }
      if (memcmp(linebuf, "/dev/", 5) != 0) {
        fprintf(logfd, "SkiffOS resize2fs: %s: expected /dev/ prefix: %s\n",
                resize2fs_conf, linebuf);
        continue;
      }

      fprintf(logfd, "SkiffOS resize2fs: resizing persist filesystem: %s\n",
              linebuf);
      pid_t id1 = fork();
      if (id1 == 0) {
        dup2(fileno(logfd), fileno(stdout));
        dup2(fileno(logfd), fileno(stderr));

        // re-use environment (in child process)
        char **r2fsargv = (char **)malloc(4 * sizeof(const char *));
        r2fsargv[0] = (char *)resize2fs_path;
        r2fsargv[1] = (char *)"-F";
        r2fsargv[2] = linebuf;
        r2fsargv[3] = NULL;
        res = execve(resize2fs_path, r2fsargv, environ);
        free(r2fsargv);
        if (res != 0) {
          res = errno;
          fprintf(logfd,
                  "SkiffOS resize2fs: failed to exec resize2fs process on %s: "
                  "(%d) %s\n",
                  linebuf, res, strerror(res));
        }
        return res;
      }

      // wait for resize2fs
      waitpid(id1, NULL, 0);
    }

    free(linebuf);
    fclose(r2conf);
  } else {
    res = errno;
    fprintf(
        logfd,
        "SkiffOS init: cannot find resize2fs, skipping: %s and %s: (%d) %s\n",
        resize2fs_path, resize2fs_conf, res, strerror(res));
    res = 0;
  }
#endif

  // mount /mnt/boot if set
#ifdef MOUNT_BOOT
  if (stat(boot_parent_mnt, &st) == -1) {
    mkdir(boot_parent_mnt, 0755);
  }
  fprintf(logfd, "SkiffOS init: mounting %s to %s...\n", mount_boot_device, boot_parent_mnt);
  unsigned long mount_boot_opts = 0;
#ifdef MOUNT_BOOT_BIND
  mount_boot_opts = MS_BIND|MS_SHARED|MS_REC;
#endif
  if (mount(mount_boot_device, boot_parent_mnt, mount_boot_fstype, mount_boot_opts, NULL) != 0) {
    res = errno;
    fprintf(logfd, "Failed to mount %s fstype %s to mount point %s: %s\n",
            mount_boot_device, mount_boot_fstype, boot_parent_mnt, strerror(res));
    res = 0;
  }
#endif

  // if mountpoint already mounted, skip to chroot
  // mkdir -p mountpoint
  if (stat(mountpoint, &st) == -1) {
    mkdir(mountpoint, 0755);
  } else {
#ifdef NO_MOVE_MOUNTPOINT_ROOT
    // if already mounted...
    // dev_t mtptDev = st.st_dev;
    // if (stat("/", &st) != -1 && mtptDev != st.st_dev) {
    if (stat(dev_mnt, &st) != -1) {
      fprintf(logfd,
              "SkiffOS init: mountpoint %s already mounted, skipping mount "
              "process.\n",
              mountpoint);
#ifdef WRITE_SKIFF_INIT_PID
      write_skiff_init_pid(getpid());
#endif // WRITE_SKIFF_INIT_PID
      chmod(mountpoint, 0755);
      chdir(mountpoint);
#ifndef NO_CHROOT_TARGET
      chroot(mountpoint);
      chdir("/");
#endif // NO_CHROOT_TARGET
      goto exec_init_proc;
    }
#endif // NO_MOVE_MOUNTPOINT_ROOT
  }

#ifdef ROOT_MAKE_SHARED
  // ensure that / is shared
  if (mount(NULL, "/", NULL, MS_REC | MS_SHARED, NULL) != 0) {
    res = errno;
    fprintf(
        logfd,
        "SkiffOS init: cannot ensure / is shared: (%d) %s\n",
        res, strerror(res));
    res = 0;
  }
#endif

  if (stat("/dev/loop-control", &st) == -1) {
    fprintf(logfd, "SkiffOS init: warning: /dev/loop-control does not exist\n");
  }

  char *root_loop = NULL;
  fprintf(logfd, "SkiffOS init: finding unused loop device...\n");
  if ((root_loop = loopdev_find_unused()) == NULL) {
    fprintf(logfd,
            "Failed to find a free loop device for the root partition.\n");
    return 1;
  }

  fprintf(logfd, "SkiffOS init: allocating loop device %s...\n", root_loop);
  if (loopdev_setup_device(squashfs_file, 0, root_loop) != 0) {
    fprintf(logfd, "Failed to associate loop device (%s) to file (%s).\n",
            root_loop, squashfs_file);
    return 1;
  }

  // check for loop device
  int i = 0;
  while (stat(root_loop, &st) == -1) {
    fprintf(logfd, "SkiffOS init: warning: loop file %s does not exist\n",
            root_loop);
    sleep(1);
    if (++i >= 10) {
      return 1;
    }
  }

  if (stat(image_mountpoint, &st) == -1) {
    mkdir(image_mountpoint, 0755);
  }
  fprintf(logfd, "SkiffOS init: mounting %s on %s to %s...\n", squashfs_file,
          root_loop, image_mountpoint);
  if (mount(root_loop, image_mountpoint, "squashfs", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "Failed to mount loop device (%s) to mount point (%s): %s\n",
            root_loop, image_mountpoint, strerror(res));
    return res;
  }

  // Mount a temporary directory on persist overlayfs over mountpoint
  if (stat(overlay_tmp_mountpoint, &st) == -1) {
    mkdir(overlay_tmp_mountpoint, 0755);
  }

  // mount a tmpfs for the new upper mountpoint & workdir
  // this makes all changes to / ephemeral and in-RAM
  // this is similar behavior to loading the system as an initramfs.
  char* overlayTmpfsArgs = NULL;
  const char* overlayTmpfsSize = MUTABLE_OVERLAY_SIZE;
  asprintf(&overlayTmpfsArgs, "size=%s,uid=0,gid=0,mode=0755", overlayTmpfsSize);
  fprintf(logfd, "SkiffOS init: mounting tmpfs %s to %s...\n", overlayTmpfsArgs,
          overlay_tmp_mountpoint);
  if (mount("tmpfs", overlay_tmp_mountpoint, "tmpfs", 0, overlayTmpfsArgs) < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount overlay tmpfs: %s: (%d) %s\n",
            overlayTmpfsArgs, res, strerror(res));
    return res;
  }
  free(overlayTmpfsArgs);

  // Create the upper & work mountpoints within the tmpfs.
  char *overlay_upper_mountpoint = NULL;
  asprintf(&overlay_upper_mountpoint, "%s/upper", overlay_tmp_mountpoint);
  if (stat(overlay_upper_mountpoint, &st) == -1) {
    mkdir(overlay_upper_mountpoint, 0755);
  }

  char *overlay_work_mountpoint = NULL;
  asprintf(&overlay_work_mountpoint, "%s/work", overlay_tmp_mountpoint);
  if (stat(overlay_work_mountpoint, &st) == -1) {
    mkdir(overlay_work_mountpoint, 0755);
  }

  // Mount overlayfs for the root filesystem
  char *overlayArgs = NULL;
  asprintf(&overlayArgs, "lowerdir=%s,upperdir=%s,workdir=%s",
          image_mountpoint, overlay_upper_mountpoint,
          overlay_work_mountpoint);
  fprintf(logfd, "SkiffOS init: mounting overlayfs %s to %s...\n", overlayArgs, mountpoint);
  if (mount("overlay", mountpoint, "overlay", 0, overlayArgs) < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount overlay: %s: (%d) %s\n",
            overlayArgs, res, strerror(res));
    return res;
  }
  free(overlayArgs);
  free(overlay_upper_mountpoint);
  free(overlay_work_mountpoint);

  // chmod the mountpoint so non-root users can use it
  if (chmod(mountpoint, 0755) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS init: failed to chmod root to a+rX: %s: (%d) %s\n",
            mountpoint, res, strerror(res));
    res = 0;
  }

  // Mount /mnt if set, otherwise, mount / directly to target
  // Note: most systems use !BIND_ROOT_MNT
#ifdef BIND_ROOT_MNT

  // Bind mount / to /mnt/persist before mounting /mnt to target.
#ifdef ROOT_AS_PERSIST
  fprintf(logfd, "SkiffOS init: mounting old / to %s\n", persist_parent_mnt);
  if (stat(persist_parent_mnt, &st) == -1) {
    mkdir(persist_parent_mnt, 0755);
  }
  if (mount("/", persist_parent_mnt, NULL, MS_BIND, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: warning: failed to mount old / as %s: (%d) %s\n",
            persist_parent_mnt, res, strerror(res));
    res = 0; // ignore
  }
#endif // ROOT_AS_PERSIST

  fprintf(logfd, "SkiffOS init: mounting old /mnt to %s...\n", mnt_mnt);
  if (stat(mnt_mnt, &st) == -1) {
    mkdir(mnt_mnt, 0755);
  }

  // rbind /mnt -> target/mnt as shared
  if (mount("/mnt", mnt_mnt, NULL, MS_BIND | MS_REC | MS_SHARED, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount /mnt in chroot: (%d) %s\n", res,
            strerror(res));
    res = 0; // ignore
  }

#else // !BIND_ROOT_MNT

  // Mount persist into the target chroot only.
#ifdef ROOT_AS_PERSIST
  fprintf(logfd, "SkiffOS init: mounting / to %s...\n", persist_mnt);
  if (stat(persist_mnt, &st) == -1) {
    mkdir(persist_mnt, 0755);
  }
  // NOTE: MS_SHARED ?
  if (mount("/", persist_mnt, NULL, MS_BIND|MS_SHARED, NULL) != 0) { // MS_REC - rbind
    res = errno;
    fprintf(logfd, "SkiffOS: warning: failed to mount / as %s: (%d) %s\n",
            persist_mnt, res, strerror(res));
    res = 0; // ignore
  }
#endif // ROOT_AS_PERSIST

  // Mount boot into the target chroot only.
#ifdef ROOT_AS_BOOT
  fprintf(logfd, "SkiffOS init: mounting parent %s to %s...\n", boot_parent_mnt, boot_mnt);
  if (stat(boot_mnt, &st) == -1) {
    mkdir(boot_mnt, 0755);
  }
  // NOTE: MS_SHARED ?
  if (mount(boot_parent_mnt, boot_mnt, NULL, MS_BIND|MS_SHARED|MS_REC, NULL) != 0) { // MS_REC - rbind
    res = errno;
    fprintf(logfd, "SkiffOS: warning: failed to mount %s as %s: (%d) %s\n",
            boot_parent_mnt, boot_mnt,
            res, strerror(res));
    res = 0; // ignore
  }
#endif // ROOT_AS_BOOT

#endif // !BIND_ROOT_MNT

  // mount /dev in target
  if (mount("/dev", dev_mnt, NULL, MS_BIND | MS_REC, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount /dev in chroot: (%d) %s\n", res,
            strerror(res));
    return res;
  }

#ifndef NO_MOUNT_PROC
  fprintf(logfd, "SkiffOS init: mounting proc to %s...\n", proc_mnt);
  if (mount("none", proc_mnt, "proc", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount proc in chroot: (%d) %s\n", res,
            strerror(res));
    res = 0;
  }
#endif

#ifndef NO_MOUNT_SYS
#ifdef MOUNT_SYS_RBIND
  fprintf(logfd, "SkiffOS init: mounting old /sys to %s...\n", sys_mnt);
  if (mount("/sys", sys_mnt, NULL, MS_BIND | MS_REC, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount /sys in chroot: (%d) %s\n", res,
            strerror(res));
    res = 0;
  }
#else
  fprintf(logfd, "SkiffOS init: mounting sysfs to %s...\n", sys_mnt);
  if (mount("sysfs", sys_mnt, "sysfs", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount sys in chroot: (%d) %s\n", res,
            strerror(res));
    res = 0;
  }
#endif
#endif

  // Bind all of the extra host dirs into the container.
  do_bind_host_paths();

  // Write PID file for init
#ifdef WRITE_SKIFF_INIT_PID
  write_skiff_init_pid(getpid());
#endif

  // Attempt to chroot into it
  fprintf(logfd, "SkiffOS init: switching into mountpoint: %s\n", mountpoint);
  chdir(mountpoint);

  // move the mount to /
  int cfd = open("/", O_RDONLY);
  if (cfd < 0) {
    res = errno;
    fprintf(logfd,
            "SkiffOS: failed to open / file descriptor, continuing: (%d) %s\n",
            res, strerror(res));
    res = 0; // ignore
  }

  // move mountpoint
#ifndef NO_MOVE_MOUNTPOINT_ROOT
  if (mount(mountpoint, "/", NULL, MS_MOVE, NULL) < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to move / mount: (%d) %s\n", res,
            strerror(res));
    return res;
  }

  // chroot into / (the mountpoint was moved)
#ifndef NO_CHROOT_TARGET
  chroot(".");
#endif

#else

  // chroot into mountpoint
#ifndef NO_CHROOT_TARGET
  chroot(mountpoint);
#endif

#endif

  chdir("/");
  if (cfd > 0) {
    close(cfd);
    cfd = 0;
  }

exec_init_proc:

  // compute new init argc and argv
  if (argc < 1) {
    argc = 1;
  }
  char **initargv = (char **)malloc((argc + 1) * sizeof(char *));
  initargv[argc] = NULL;
  initargv[0] = strdup(init_proc);
  for (i = 1; i < argc; i++) { // skip argv[0]
    size_t len = strlen(argv[i]) + 1;
    initargv[i] = malloc(len * sizeof(char));
    memcpy(initargv[i], argv[i], len);
  }

  // exec init
  fprintf(logfd, "SkiffOS init: executing init process: %s\n", init_proc);
  if (closeLogFd) {
    fclose(logfd);
    logfd = stderr;
  }

  // re-use environment
  if (execve(init_proc, initargv, environ) != 0) {
    res = errno;
    fprintf(logfd, "Failed to exec init process\n");
    fprintf(logfd, "Error (%d) %s\n", res, strerror(res));
    return res;
  }

  for (i = 0; i < argc; i++) {
    free(initargv[i]);
  }
  free(initargv);
  return 0;
}

// Based on the following utility:
// https://github.com/alexchamberlain/piimg/blob/master/src/piimg-mount.c
static const char LOOPDEV_PREFIX[] = "/dev/loop";
static int LOOPDEV_PREFIX_LEN =
    sizeof(LOOPDEV_PREFIX) / sizeof(LOOPDEV_PREFIX[0]) - 1;
int escalate() {
  if (seteuid(0) == -1 || geteuid() != 0) {
    fprintf(logfd, "Failed to escalate privileges.\n");
    return 1;
  }

  return 0;
}

char *loopdev_find_unused() {
  int control_fd = -1;
  int n = -1;

  if (escalate())
    return NULL;

  if ((control_fd = open("/dev/loop-control", O_RDWR)) < 0) {
    fprintf(logfd, "Failed to open /dev/loop-control\n");
    return NULL;
  }

  n = ioctl(control_fd, LOOP_CTL_GET_FREE);

  if (n < 0) {
    fprintf(logfd, "Failed to find a free loop device.\n");
    return NULL;
  }

  int l =
      strlen(LOOPDEV_PREFIX) + 1 + 1; /* 1 for first character, 1 for NULL */
  {
    int m = n;
    while (m /= 10) {
      ++l;
    }
  }

  char *loopdev = (char *)malloc(l * sizeof(char));
  assert(sprintf(loopdev, "%s%d", LOOPDEV_PREFIX, n) == l - 1);

  return loopdev;
}

int loopdev_setup_device(const char *file, uint64_t offset,
                         const char *device) {
  int file_fd = open(file, O_RDWR);
  int device_fd = -1;

  struct loop_info64 info;

  if (file_fd < 0) {
    fprintf(logfd, "Failed to open backing file (%s).\n", file);
    goto error;
  }

  if (escalate())
    goto error;

  if ((device_fd = open(device, O_RDWR)) < 0) {
    fprintf(logfd, "Failed to open device (%s).\n", device);
    goto error;
  }

  if (ioctl(device_fd, LOOP_SET_FD, file_fd) < 0) {
    fprintf(logfd, "Failed to set fd.\n");
    goto error;
  }

  close(file_fd);
  file_fd = -1;

  memset(&info, 0, sizeof(struct loop_info64)); /* Is this necessary? */
  info.lo_offset = offset;
  /* info.lo_sizelimit = 0 => max available */
  /* info.lo_encrypt_type = 0 => none */

  if (ioctl(device_fd, LOOP_SET_STATUS64, &info)) {
    fprintf(logfd, "Failed to set info.\n");
    goto error;
  }

  close(device_fd);
  device_fd = -1;

  return 0;

error:
  if (file_fd >= 0) {
    close(file_fd);
  }
  if (device_fd >= 0) {
    ioctl(device_fd, LOOP_CLR_FD, 0);
    close(device_fd);
  }
  return 1;
}

void write_skiff_init_pid(pid_t pid) {
#ifdef WRITE_SKIFF_INIT_PID
  fprintf(logfd, "SkiffOS init: writing PID file: %s: %d\n", init_pid_path, pid);
  int pidfd;
  FILE *pidf;
  struct stat st = {0};
  char *init_pid_pathf = strdup(init_pid_path);
  char *init_pid_dir = dirname(init_pid_pathf);
  if (stat(init_pid_dir, &st) != 0) {
    mkdir(init_pid_dir, 0644);
  }
  free(init_pid_pathf);
  if (stat(init_pid_path, &st) == 0) {
    unlink(init_pid_path);
  }
  if ((pidfd = open(init_pid_path, O_WRONLY|O_CREAT|O_TRUNC, 0644)) <= 0 ||
      (pidf = fdopen(pidfd, "w")) == NULL) {
    fprintf(logfd, "SkiffOS init: failed to write pid file to %s: (%d) %s\n",
            init_pid_path, errno, strerror(errno));
    if (pidfd > 0) {
      close(pidfd);
    }
    return;
  }
  if (!fprintf(pidf, "%d\n", pid)) {
    fprintf(logfd, "SkiffOS init: failed to write pid file to %s: (%d) %s\n",
            init_pid_path, errno, strerror(errno));
  }
  fflush(pidf);
  close(pidfd);
#endif
}

int unlink_cb(const char *fpath, const struct stat *sb, int typeflag,
              struct FTW *ftwbuf) {
  int rv = remove(fpath);

  if (rv)
    perror(fpath);

  return rv;
}

int rmrf(char *path) { return nftw(path, unlink_cb, 64, FTW_DEPTH | FTW_PHYS); }

// do_bind_host_paths binds any extra host dirs defined in BIND_HOST_PATHS.
void do_bind_host_paths(void) {
  struct stat st, stSrc = {0};
  const char* bhd = BIND_HOST_PATHS;
  int bhdlen = strlen(bhd);
  int mtptlen = strlen(mountpoint);
  int res = 0;
  int bhdskiptws = 0;
  for (int i1 = 0; i1 < bhdlen; i1++) {
  nextbhdmatch:
    // skip until whitespaces
    if (bhdskiptws) {
      bhdskiptws = 0;
      while (i1 < bhdlen && bhd[i1] != ' ') {
        i1++;
      }
      continue;
    }
    // skip whitespaces
    if (i1 >= bhdlen || bhd[i1] == ' ') {
      continue;
    }
    // evaluate value
    const char* mhost_path = &bhd[i1];
    int mhost_len = 1;
    const char* mtarget_path = 0;
    int mtarget_len = 0;
    int tpath = 0;
    i1++;
    for (; i1 < bhdlen && bhd[i1] != ' '; i1++) {
      if (bhd[i1] == ':') {
        if (tpath) {
          // ERROR: more than 1 : in the string.
          // fast forward to next space and continue.
          bhdskiptws = 1;
          goto nextbhdmatch;
        }
        tpath = 1;
        mtarget_path = &bhd[i1+1];
        continue;
      }
      if (!tpath) {
        mhost_len++;
      } else {
        mtarget_len++;
      }
    }
    if (mhost_len == 0 || mtarget_len == 0) {
      continue;
    }

    char* host_path = malloc((mhost_len+1) * sizeof(char));
    memcpy(host_path, mhost_path, mhost_len);
    host_path[mhost_len] = 0;

    // prefix target dir with the chroot path.
    char *target_path = malloc(mtptlen + (mtarget_len + 1) * sizeof(char));
    memcpy(target_path, mountpoint, mtptlen);
    memcpy(target_path+mtptlen, mtarget_path, mtarget_len);
    target_path[mtarget_len+mtptlen] = 0;

    if (stat(host_path, &stSrc) != 0) {
      fprintf(logfd, "SkiffOS init: extra bind path: %s -> %s: "
              "host path does not exist\n",
              host_path, target_path);
      goto skipbhdmount;
    }

    int path_is_dir = S_ISDIR(stSrc.st_mode);

    // if the target does exist, compare the file mode.
    // re-create if the modes are different.
    if (stat(target_path, &st) == 0) {
      if (stSrc.st_mode != st.st_mode) {
        rmrf(target_path);
      }
    }

    // if the target doesn't exist: create it
    if (stat(target_path, &st) != 0) {
      // copy permissions from the source
      int path_perms = stSrc.st_mode & 0777;
      res = 0;
      if (path_is_dir) {
        if (mkdir(target_path, path_perms) != 0) {
          res = errno;
        }
      } else {
        int touchFd = open(target_path, O_RDWR | O_CREAT, path_perms);
        if (touchFd < 0) {
          res = errno;
        } else {
          close(touchFd);
        }
      }
      if (res != 0) {
        res = errno;
        fprintf(logfd,
                "SkiffOS init: extra bind path: %s -> %s: "
                "cannot create target path: (%d) %s\n",
                host_path, target_path, res, strerror(res));
        goto skipbhdmount;
      }
    }

    unsigned long int flags = MS_BIND;
    if (path_is_dir) {
      flags = flags | MS_REC;
    }
    if (mount(host_path, target_path, NULL, flags, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS: failed to mount extra bind path %s -> %s: "
              "(%d) %s\n", host_path, target_path, res, strerror(res));
      goto skipbhdmount;
    }

    fprintf(logfd, "SkiffOS init: mounted extra bind path: %s -> %s\n",
            host_path, target_path);

  skipbhdmount:
    free(host_path);
    free(target_path);
  }
}
