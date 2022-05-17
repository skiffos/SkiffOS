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
// #include <sys/wait.h>

// Set the path to kexec (required)
// #define KEXEC_PATH "/boot/skiff-init/kexec"

// Set the kernel path to load (required)
// #define KEXEC_KERNEL "/boot/Image"

// Override the entire kernel cmdline.
// #define KEXEC_CMDLINE "init=/path/to/init root=..."

// Append arguments to the kernel cmdline instead of replace.
// #define KEXEC_CMDLINE_APPEND

// Re-use the command line from the previous system.
// #define KEXEC_CMDLINE_REUSE

// Load an initramfs.
// #define KEXEC_INITRD "/boot/rootfs.cpio"

const char *kernel_path = KEXEC_KERNEL;
const char *initrd_path = NULL;
#ifdef KEXEC_INITRD
initrd_path = KEXEC_INITRD;
#endif

FILE *logfd;
const char *pid1_log = "/dev/kmsg";

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
      res = 0; // ignore
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

  // if ! mountpoint /proc; mount -t proc proc /proc; fi
  if (stat("/proc/stat", &st) != 0) {
    if (mount("proc", "/proc", "proc", 0, NULL) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS init: failed to mount /proc: (%d) %s\n", res,
              strerror(res));
    }
  }

  // Generate kexec arguments.
  int kexecArgN = 0;
  char **kexecArgv = (char **)malloc(256 * sizeof(const char *));
#define PUSH_ARG(ARG) kexecArgv[kexecArgN++] = ARG;

  // Execute right away (skip the shutdown step.)
  PUSH_ARG("-e");

  // Use kexec_file which does not require CONFIG_SUSPEND.
  PUSH_ARG("-s");

  // Load the specified kernel.
#ifdef KEXEC_KERNEL
  PUSH_ARG("-l");
  PUSH_ARG(KEXEC_KERNEL);
#endif

  // Override the cmdline.
#ifdef KEXEC_CMDLINE
#ifdef KEXEC_CMDLINE_APPEND
  PUSH_ARG("--append");
#else
  PUSH_ARG("--command-line");
#endif
  PUSH_ARG(KEXEC_CMDLINE);
#endif

  // Reuse the existing cmdline.
#ifdef KEXEC_CMDLINE_REUSE
  PUSH_ARG("--reuse-cmdline");
#endif

  // Use an init ramdisk
#ifdef KEXEC_INITRD
  PUSH_ARG("--ramdisk");
  PUSH_ARG(KEXEC_CMDLINE_REUSE);
#endif

  // Set null terminator on the args.
  fprintf(logfd, "\n");
  kexecArgv[kexecArgN] = NULL;

  // Execute kexec!
  fprintf(logfd, "SkiffOS init: executing kexec\n");
  if (execve(KEXEC_PATH, kexecArgv, environ) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS init: failed to kexec: (%d): %s\n", res, strerror(res));
  }
  return res;
}
