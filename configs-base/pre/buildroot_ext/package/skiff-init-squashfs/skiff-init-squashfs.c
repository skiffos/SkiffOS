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

// To mount / to /mnt/persist:
// #define ROOT_AS_PERSIST

// To disable resizing persist
// #define NO_RESIZE_PERSIST

// To disable the mutable / overlayfs:
// #define NO_MUTABLE_OVERLAY

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

const char *init_proc = SKIFF_INIT_PROC;
const char *init_pid_path = SKIFF_INIT_PID;

FILE *logfd;
const char *pid1_log = "/dev/kmsg";
const char *squashfs_file = "/boot/rootfs.squashfs";

const char *resize2fs_path = "/boot/skiff-init/resize2fs";
const char *resize2fs_conf = "/boot/skiff-init/resize2fs.conf";

#ifndef SKIFF_MOUNTS_DIR
#define SKIFF_MOUNTS_DIR "/skiff-overlays"
#define SKIFF_MOUNTPOINT SKIFF_MOUNTS_DIR "/system"
#endif

const char *root_dir = SKIFF_MOUNTS_DIR;
const char *mountpoint = SKIFF_MOUNTPOINT;
const char *dev_mnt = SKIFF_MOUNTPOINT "/dev";
const char *run_mnt = SKIFF_MOUNTPOINT "/run";
const char *sys_mnt = SKIFF_MOUNTPOINT "/sys";
const char *mnt_mnt = SKIFF_MOUNTPOINT "/mnt";
const char *persist_mnt = SKIFF_MOUNTPOINT "/mnt/persist";
const char *persist_parent_mnt = "/mnt/persist";
const char *image_mountpoint = SKIFF_MOUNTS_DIR "/image";

#ifndef NO_MUTABLE_OVERLAY
const char *overlay_upper_mountpoint = SKIFF_MOUNTS_DIR "/system-upper";
const char *overlay_work_mountpoint = SKIFF_MOUNTS_DIR "/system-tmp";
#endif

// Set BIND_HOST_DIRS to a space-separated list of paths to bind mount:
// Each path should be host-dir:target-dir
// i.e. /mydir:/my-target-dir /my-other-dir:/my-other-target-dir
#ifndef BIND_HOST_DIRS
#define BIND_HOST_DIRS ""
#endif

char *loopdev_find_unused();
int loopdev_setup_device(const char *file, uint64_t offset, const char *device);
void write_skiff_init_pid(pid_t pid);
void do_bind_host_dirs(void);

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
      if (mount("devtmpfs", "/dev", "devtmpfs", 0, NULL) != 0) {
        res = errno;
        fprintf(logfd,
                "SkiffOS init: failed to mount root /dev devtmpfs: (%d) %s\n",
                res, strerror(res));
        res = 0; // ignore for now
        // return res;
      }
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

  // mount /etc/mtab /proc if not mounted
  if (stat("/etc", &st) == -1) {
    mkdir("/etc", 0755);
  }

  if (stat("/proc", &st) == -1) {
    mkdir("/proc", 0555);
  }

  // if ! mountpoint /proc; mount -t proc proc /proc; fi
  if (stat("/proc/stat", &st) != 0) {
    if (mount("proc", "/proc", "proc", 0, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS init: failed to mount /proc: (%d) %s\n", res,
              strerror(res));
    }
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

  // resize root filesystem if necessary
  // it is assumed that root= was set to the "persist" partition and that the
  // boot data is stored in /boot. this may be changed later to support more
  // exotic setups.
#ifndef NO_RESIZE_PERSIST
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
        // re-use environment (in child process)
        char **r2fsargv = (char **)malloc(4 * sizeof(const char *));
        r2fsargv[0] = (char *)resize2fs_path;
        r2fsargv[1] = (char *)"-F";
        r2fsargv[2] = linebuf;
        r2fsargv[3] = NULL;
        dup2(fileno(logfd), fileno(stdout));
        dup2(fileno(logfd), fileno(stderr));
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
#endif
      chmod(mountpoint, 0755);
      chdir(mountpoint);
#ifndef NO_CHROOT_TARGET
      chroot(mountpoint);
      chdir("/");
#endif
      goto exec_init_proc;
    }
#endif
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
#ifndef NO_MUTABLE_OVERLAY
  if (stat(overlay_upper_mountpoint, &st) == -1) {
    mkdir(overlay_upper_mountpoint, 0755);
  }
  if (stat(overlay_work_mountpoint, &st) == -1) {
    mkdir(overlay_work_mountpoint, 0755);
  }

  // move the squashfs to the new lower mountpoint
  // TODO better to mount ramfs to upper mountpoint?
  // TODO wipe upper and workdir if already exist?
  // mount overlayfs for mutable root
  char *overlayArgs = (char *)malloc(60 + strlen(image_mountpoint) +
                                     strlen(overlay_upper_mountpoint) +
                                     strlen(overlay_work_mountpoint));
  sprintf(overlayArgs, "lowerdir=%s,upperdir=%s,workdir=%s",
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

  // attempt to make the mountpoint shared
  mount(NULL, mountpoint, NULL, MS_SHARED|MS_REC, NULL);

#endif

  // chmod the mountpoint so non-root users can use it
  if (chmod(mountpoint, 0755) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS init: failed to chmod root to a+rX: %s: (%d) %s\n",
            mountpoint, res, strerror(res));
    res = 0;
  }

  // Mount /mnt if set
#ifdef BIND_ROOT_MNT

  if (stat("/mnt", &st) == -1) {
    mkdir("/mnt", 0755);
  }

  // Bind mount / to /mnt/persist before mounting /mnt to target.
#ifdef ROOT_AS_PERSIST
  fprintf(logfd, "SkiffOS init: mounting old / to %s\n", persist_parent_mnt);
  if (stat(persist_parent_mnt, &st) == -1) {
    mkdir(persist_parent_mnt, 0755);
  }
  if (mount("/", persist_parent_mnt, NULL, MS_BIND | MS_SHARED, NULL) != 0) { // MS_REC - rbind
    res = errno;
    fprintf(logfd, "SkiffOS: warning: failed to mount old / as %s: (%d) %s\n",
            persist_mnt, res, strerror(res));
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
  if (mount("/", persist_mnt, NULL, MS_BIND|MS_SHARED, NULL) != 0) { // MS_REC - rbind
    res = errno;
    fprintf(logfd, "SkiffOS: warning: failed to mount / as %s: (%d) %s\n",
            persist_mnt, res, strerror(res));
    res = 0; // ignore
  }
#endif // ROOT_AS_PERSIST

#endif // BIND_ROOT_MNT

#ifndef NO_MOUNT_SYS
#ifdef MOUNT_SYS_RBIND
  fprintf(logfd, "SkiffOS init: mounting old /sys to %s...\n", sys_mnt);
  if (mount("/sys", sys_mnt, NULL, MS_BIND | MS_REC, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount /sys in chroot: (%d) %s\n", res,
            strerror(res));
    return res;
  }
#endif
#endif

  // Write PID file for init
#ifdef WRITE_SKIFF_INIT_PID
  write_skiff_init_pid(getpid());
#endif

  // Bind /dev into the container if set.
  if (stat("/dev", &st) == 0) {
    if (mount("/dev", dev_mnt, NULL, MS_BIND | MS_REC, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS: failed to mount /dev in chroot: (%d) %s\n", res,
              strerror(res));
      return res;
    }
  }

  // Bind all of the extra host dirs into the container.
  do_bind_host_dirs();

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
  chroot("/");
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

#ifndef NO_MOUNT_PROC
  if (mount("none", "/proc", "proc", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount proc in chroot: (%d) %s\n", res,
            strerror(res));
    return res;
  }
#endif

#ifndef NO_MOUNT_SYS
#ifndef MOUNT_SYS_RBIND
  if (mount("/sys", "/sys", "sysfs", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount /sys in chroot: (%d) %s\n", res,
            strerror(res));
    return res;
  }
#endif
#endif

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

// do_bind_host_dirs binds any extra host dirs defined in BIND_HOST_DIRS.
void do_bind_host_dirs(void) {
  struct stat st = {0};
  const char* bhd = BIND_HOST_DIRS;
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
    const char* mhost_dir = &bhd[i1];
    int mhost_len = 1;
    const char* mtarget_dir = 0;
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
        mtarget_dir = &bhd[i1+1];
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

    char* host_dir = malloc((mhost_len+1) * sizeof(char));
    memcpy(host_dir, mhost_dir, mhost_len);
    host_dir[mhost_len] = 0;

    // prefix target dir with the chroot path.
    char *target_dir = malloc(mtptlen + (mtarget_len + 1) * sizeof(char));
    memcpy(target_dir, mountpoint, mtptlen);
    memcpy(target_dir+mtptlen, mtarget_dir, mtarget_len);
    target_dir[mtarget_len+mtptlen] = 0;

    if (stat(host_dir, &st) != 0) {
      fprintf(logfd, "SkiffOS init: extra bind path: %s -> %s: "
              "host dir does not exist\n",
              host_dir, target_dir);
      goto skipbhdmount;
    }
    if (stat(target_dir, &st) != 0) {
      if (mkdir(target_dir, 0755) != 0) {
        res = errno;
        fprintf(logfd,
                "SkiffOS init: extra bind path: %s -> %s: "
                "cannot create target dir: (%d) %s\n",
                host_dir, target_dir, res, strerror(res));
        goto skipbhdmount;
      }
    }

    if (mount(host_dir, target_dir, NULL, MS_BIND | MS_REC, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS: failed to mount extra bind path %s -> %s: (%d) %s\n", host_dir, target_dir, res,
              strerror(res));
      goto skipbhdmount;
    }

    fprintf(logfd, "SkiffOS init: mounted extra bind path: %s -> %s\n",
            host_dir, target_dir);

  skipbhdmount:
    free(host_dir);
    free(target_dir);
  }
}
