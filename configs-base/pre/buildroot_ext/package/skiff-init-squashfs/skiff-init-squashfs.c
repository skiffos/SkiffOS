#define _GNU_SOURCE
#include <errno.h>
#include <stdlib.h>
#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>
#include <string.h>
#include <assert.h>
#include <stdint.h>

#include <sys/mount.h>
#include <sys/types.h>
#include <sys/wait.h>
#include <sys/stat.h>

#include <linux/loop.h>

FILE* logfd;

// Based on the following utility:
// https://github.com/alexchamberlain/piimg/blob/master/src/piimg-mount.c
static const char LOOPDEV_PREFIX[]   = "/dev/loop";
static int        LOOPDEV_PREFIX_LEN = sizeof(LOOPDEV_PREFIX)/sizeof(LOOPDEV_PREFIX[0])-1;
int escalate() {
  if(seteuid(0) == -1 || geteuid() != 0) {
    fprintf(logfd, "Failed to escalate privileges.\n");
    return 1;
  }

  return 0;
}

char * loopdev_find_unused() {
  int control_fd = -1;
  int n = -1;

  if(escalate()) return NULL;

  if((control_fd = open("/dev/loop-control", O_RDWR)) < 0) {
    fprintf(logfd, "Failed to open /dev/loop-control\n");
    return NULL;
  }

  n = ioctl(control_fd, LOOP_CTL_GET_FREE);

  if(n < 0) {
    fprintf(logfd, "Failed to find a free loop device.\n");
    return NULL;
  }

  int l = strlen(LOOPDEV_PREFIX) + 1 + 1; /* 1 for first character, 1 for NULL */
  {
    int m = n;
    while(m /= 10) {
      ++l;
    }
  }

  char * loopdev = (char*) malloc(l * sizeof(char));
  assert(sprintf(loopdev, "%s%d", LOOPDEV_PREFIX, n) == l - 1);

  return loopdev;
}

int loopdev_setup_device(const char * file, uint64_t offset, const char * device) {
  int file_fd = open(file, O_RDWR);
  int device_fd = -1;

  struct loop_info64 info;

  if(file_fd < 0) {
    fprintf(logfd, "Failed to open backing file (%s).\n", file);
    goto error;
  }

  if(escalate()) goto error;

  if((device_fd = open(device, O_RDWR)) < 0) {
    fprintf(logfd, "Failed to open device (%s).\n", device);
    goto error;
  }

  if(ioctl(device_fd, LOOP_SET_FD, file_fd) < 0) {
    fprintf(logfd, "Failed to set fd.\n");
    goto error;
  }

  close(file_fd);
  file_fd = -1;

  memset(&info, 0, sizeof(struct loop_info64)); /* Is this necessary? */
  info.lo_offset = offset;
  /* info.lo_sizelimit = 0 => max available */
  /* info.lo_encrypt_type = 0 => none */

  if(ioctl(device_fd, LOOP_SET_STATUS64, &info)) {
    fprintf(logfd, "Failed to set info.\n");
    goto error;
  }

  close(device_fd);
  device_fd = -1;

  return 0;

  error:
    if(file_fd >= 0) {
      close(file_fd);
    }
    if(device_fd >= 0) {
      ioctl(device_fd, LOOP_CLR_FD, 0);
      close(device_fd);
    }
    return 1;
}

#ifndef MS_MOVE
#define MS_MOVE 8192
#endif

#ifndef MNT_DETACH
#define MNT_DETACH 0x00000002
#endif

#define MAX_RESIZE2FS_DEV_LEN 256

// To disable mounting /mnt/persist:
// #define NO_ROOT_AS_PERSIST

// To disable the mutable / overlayfs:
// #define NO_MUTABLE_OVERLAY

// To disable the moving mountpoint to /
// #define NO_MOVE_MOUNTPOINT_ROOT

// TODO: Convert to defines and/or allow overriding from Config.in
const char* pid1_log = "/dev/kmsg"; // "/dev/ttyS0";
const char* squashfs_file = "/boot/rootfs.squashfs";

const char* resize2fs_path = "/boot/skiff-init/resize2fs";
const char* resize2fs_conf = "/boot/skiff-init/resize2fs.conf";

const char* root_dir = "/skiff-overlays";
const char* mountpoint = "/skiff-overlays/system";
const char* dev_mnt = "/skiff-overlays/system/dev";
const char* proc_mnt = "/skiff-overlays/system/proc";
const char* sys_mnt = "/skiff-overlays/system/sys";
const char* run_mnt = "/skiff-overlays/system/run";
const char* persist_mnt = "/skiff-overlays/system/mnt/persist";

const char* init_proc = "/lib/systemd/systemd";

#ifndef NO_MUTABLE_OVERLAY
const char* overlay_lower_mountpoint = "/skiff-overlays/system-image";
const char* overlay_upper_mountpoint = "/skiff-overlays/system-upper";
const char* overlay_work_mountpoint = "/skiff-overlays/system-tmp";
#endif

int main(int argc, char* argv[]) {
  int res = 0;
  logfd = stderr;
  int closeLogFd = 0;
  struct stat st = {0};

  // log to uart, mount /dev
  if (getpid() == 1) {
    // mkdir -p /dev
    if (stat("/dev", &st) == -1) {
      mkdir("/dev", 0755);
      if(mount("devtmpfs", "/dev", "devtmpfs", 0, NULL) != 0) {
        res = errno;
        fprintf(logfd, "SkiffOS init: failed to mount root /dev devtmpfs: (%d) %s\n", res, strerror(res));
        res = 0; // ignore for now
        // return res;
      }
    }

    logfd = fopen(pid1_log, "w");
    if (logfd == 0) {
      fprintf(logfd, "Failed to open %s as PID 1: %s\n", pid1_log, strerror(errno));
      logfd = stderr;
    } else {
      setbuf(logfd, NULL);
      closeLogFd = 1;
    }
  }

  // mkdir -p ${root_dir}
  if (stat(root_dir, &st) == -1) {
    mkdir(root_dir, 0700);
  }

  // mount /etc/mtab /proc if not mounted
  if (stat("/proc", &st) == -1) {
    mkdir("/proc", 0555);
  }
  if (stat("/etc", &st) == -1) {
    mkdir("/etc", 0755);
  }
  if(mount("proc", "/proc", "proc", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS init: failed to mount /proc: (%d) %s\n", res, strerror(res));
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
      fprintf(logfd, "SkiffOS: failed to create mtab symlink: (%d) %s\n", res, strerror(res));
      res = 0;
    }
  }


  // resize root filesystem if necessary
  // it is assumed that root= was set to the "persist" partition and that the boot data is stored in /boot.
  // this may be changed later to support more exotic setups.
#ifndef NO_RESIZE_ROOT
  if (stat(resize2fs_path, &st) == 0 && stat(resize2fs_conf, &st) == 0) {
    // read the path(s) to resize from the conf file.
    // all lines not starting with # are assumed to be paths to device files.
    // all lines must have a /dev prefix.
    FILE* r2conf = fopen(resize2fs_conf, "r");
    char* linebuf = (char*)malloc(MAX_RESIZE2FS_DEV_LEN*sizeof(char));
    while (fgets(linebuf, MAX_RESIZE2FS_DEV_LEN - 1, r2conf)) {
      linebuf[MAX_RESIZE2FS_DEV_LEN-1] = 0;
      if (linebuf[0] == '#') {
        continue;
      }
      linebuf[strcspn(linebuf, "\n")] = 0;
      linebuf[strcspn(linebuf, " ")] = 0;
      if (strlen(linebuf) < 6) {
        fprintf(logfd, "SkiffOS resize2fs: %s: line too short: %s\n", resize2fs_conf, linebuf);
        continue;
      }
      if (memcmp(linebuf, "/dev/", 5) != 0) {
        fprintf(logfd, "SkiffOS resize2fs: %s: expected /dev/ prefix: %s\n", resize2fs_conf, linebuf);
        continue;
      }

      fprintf(logfd, "SkiffOS resize2fs: resizing persist filesystem: %s\n", linebuf);
      pid_t id1 = fork();
      if (id1 == 0) {
        // re-use environment (in child process)
        char** r2fsargv = (char**)malloc(4 * sizeof(const char*));
        r2fsargv[0] = (char*)resize2fs_path;
        r2fsargv[1] = (char*)"-F";
        r2fsargv[2] = linebuf;
        r2fsargv[3] = NULL;
        dup2(fileno(logfd), fileno(stdout));
        dup2(fileno(logfd), fileno(stderr));
        res = execve(resize2fs_path, r2fsargv, environ);
        free(r2fsargv);
        if (res != 0) {
          res = errno;
          fprintf(logfd, "SkiffOS resize2fs: failed to exec resize2fs process on %s: (%d) %s\n", linebuf, res, strerror(res));
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
    fprintf(logfd, "SkiffOS init: cannot find resize2fs, skipping: %s and %s: (%d) %s\n", resize2fs_path, resize2fs_conf, res, strerror(res));
    res = 0;
  }
#endif

  char* root_loop = NULL;
  fprintf(logfd, "SkiffOS init: finding unused loop device...\n", root_loop);
  if((root_loop = loopdev_find_unused()) == NULL) {
    fprintf(logfd, "Failed to find a free loop device for the root partition.\n");
    return 1;
  }

  fprintf(logfd, "SkiffOS init: allocating loop device %s...\n", root_loop);
  if(loopdev_setup_device(squashfs_file, 0, root_loop) != 0) {
    fprintf(logfd, "Failed to associate loop device (%s) to file (%s).\n", root_loop, squashfs_file);
    return 1;
  }

  // mkdir -p mountpoint
  if (stat(mountpoint, &st) == -1) {
    mkdir(mountpoint, 0700);
  }

  // check for loop device
  int i = 0;
  while (stat(root_loop, &st) == -1) {
    fprintf(logfd, "SkiffOS init: warning: loop file %s does not exist\n", root_loop);
    sleep(1);
    if (++i >= 10) {
      return 1;
    }
  }

  fprintf(logfd, "SkiffOS init: mounting %s on %s to %s...\n", squashfs_file, root_loop, mountpoint);
  if(mount(root_loop, mountpoint, "squashfs", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "Failed to mount loop device (%s) to mount point (%s): %s\n", root_loop, mountpoint, strerror(res));
    return res;
  }

  // Mount a temporary directory on persist overlayfs over mountpoint
#ifndef NO_MUTABLE_OVERLAY
  if (stat(overlay_lower_mountpoint, &st) == -1) {
    mkdir(overlay_lower_mountpoint, 0700);
  }
  if (stat(overlay_upper_mountpoint, &st) == -1) {
    mkdir(overlay_upper_mountpoint, 0700);
  }
  if (stat(overlay_work_mountpoint, &st) == -1) {
    mkdir(overlay_work_mountpoint, 0700);
  }

  // move the squashfs to the new lower mountpoint
  fprintf(logfd, "SkiffOS init: binding image mount to %s...\n", overlay_lower_mountpoint);
  if (mount(mountpoint, overlay_lower_mountpoint, NULL, MS_BIND, NULL) < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to bind mount: (%d) %s\n", res, strerror(res));
    return res;
	}

  // TODO better to mount ramfs to upper mountpoint?
  // TODO wipe upper and workdir if already exist?
  fprintf(logfd, "SkiffOS init: mutable tree is at %s...\n", overlay_upper_mountpoint);
  fprintf(logfd, "SkiffOS init: overlay workdir is at %s...\n", overlay_work_mountpoint);

  // mount overlayfs for mutable root
  fprintf(logfd, "SkiffOS init: mounting overlayfs to %s...\n", mountpoint);
  char* overlayArgs = (char*)malloc(60+strlen(overlay_lower_mountpoint)+strlen(overlay_upper_mountpoint)+strlen(overlay_work_mountpoint));
  sprintf(overlayArgs, "lowerdir=%s,upperdir=%s,workdir=%s", overlay_lower_mountpoint, overlay_upper_mountpoint, overlay_work_mountpoint);
  if (mount("overlay", mountpoint, "overlay", 0, overlayArgs) < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount overlay: %s: (%d) %s\n", overlayArgs, res, strerror(res));
    return res;
	}
  free(overlayArgs);

#endif

  // chmod the mountpoint so non-root users can use it
  if (chmod(mountpoint, 0755) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS init: failed to chmod root to a+rX: %s: (%d) %s\n", mountpoint, res, strerror(res));
    res = 0;
  }

  // Mount persist if set
#ifndef NO_ROOT_AS_PERSIST
  fprintf(logfd, "SkiffOS init: mounting old / to %s...\n", persist_mnt);
  if (stat(persist_mnt, &st) == -1) {
    mkdir(persist_mnt, 0755);
  }
  if(mount("/", persist_mnt, NULL, MS_BIND, NULL) != 0) { // MS_REC - rbind
    res = errno;
    fprintf(logfd, "SkiffOS: warning: failed to mount old / as %s: (%d) %s\n", persist_mnt, res, strerror(res));
    res = 0; // ignore
  }
#endif

  // Attempt to chroot into it
  fprintf(logfd, "SkiffOS init: switching into mountpoint: %s\n", mountpoint);
  fprintf(logfd, "SkiffOS init: mounting /dev /proc /sys...\n");
  if (stat("/dev", &st) == 0) {
    if(mount("/dev", dev_mnt, NULL, MS_BIND|MS_REC, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS: failed to mount /dev in chroot: (%d) %s\n", res, strerror(res));
      return res;
    }
  }

  if(mount("none", proc_mnt, "proc", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount proc in chroot: (%d) %s\n", res, strerror(res));
    return res;
  }

  if(mount("sysfs", sys_mnt, "sysfs", 0, NULL) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to mount /sys in chroot: (%d) %s\n", res, strerror(res));
    return res;
  }

  chdir(mountpoint);

  // move the mount to /
  int cfd = open("/", O_RDONLY);
  if (cfd < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to open / file descriptor, continuing: (%d) %s\n", res, strerror(res));
    res = 0; // ignore
  }

  // move mountpoint
#ifndef NO_MOVE_MOUNTPOINT_ROOT
  if (mount(mountpoint, "/", NULL, MS_MOVE, NULL) < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to move / mount: (%d) %s\n", res, strerror(res));
    return res;
	}
  chroot(".");
#else
  chroot(mountpoint);
#endif

  chdir("/");
  if (cfd > 0) {
    close(cfd);
    cfd = 0;
  }

  // compute new init argc and argv
  if (argc < 1) {
    argc = 1;
  }
  char** initargv = (char**)malloc((argc + 1) * sizeof(char*));
  initargv[0] = strdup(init_proc);
  for (i = 1; i < argc; i++) { // skip argv[0]
    size_t len = strlen(argv[i])+1;
    initargv[i] = malloc(len*sizeof(char));
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

