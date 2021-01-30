#define _GNU_SOURCE
#include <assert.h>
#include <errno.h>
#include <fcntl.h>
#include <pwd.h>
#include <sched.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#include <linux/limits.h>
#include <sys/mount.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <sys/wait.h>

#ifndef MS_MOVE
#define MS_MOVE 8192
#endif

#ifndef MNT_DETACH
#define MNT_DETACH 0x00000002
#endif

#define MAX_RESIZE2FS_DEV_LEN 256

#ifndef SKIFF_MOUNTPOINT
#define SKIFF_MOUNTPOINT "/skiff-overlays/system"
#endif

// PID file to get pid from for retrieving namespaces.
#ifndef SKIFF_INIT_PID
// #define SKIFF_INIT_PID "/run/skiff-init/skiff-init.pid"
#define SKIFF_INIT_PID "/skiff-overlays/skiff-init/skiff-init.pid"
#endif

// Set the path to skiff-init to run if pid is not active.
#ifndef SKIFF_INIT_PATH
#define SKIFF_INIT_PATH "/boot/skiff-init/skiff-init-squashfs"
#endif

#ifndef DEFAULT_SHELL
#define DEFAULT_SHELL "/bin/bash"
#endif

// INIT_WAIT_PID_MAX is the amount of time to wait before starting init.
#ifndef INIT_WAIT_PID_MAX
#define INIT_WAIT_PID_MAX 1000 * 5 // 5 seconds
#endif
#ifndef WAIT_PID_MAX
#define WAIT_PID_MAX 1000 * 10 // 10 seconds
#endif
#ifndef WAIT_PID_POLL_DUR
#define WAIT_PID_POLL_DUR 200
#endif
#ifndef WAIT_PID_MAX_ATTEMPTS
#define WAIT_PID_MAX_ATTEMPTS 10
#endif

// Set to disable restoring OLDPWD inside the target (if exists)
// #ifndef NO_RESTORE_PWD

// To disable chroot before running shell
// #define NO_CHROOT_TARGET

// To disable dropping environment before running shell
// #define NO_DROP_ENV

FILE *logfd;

const char *mountpoint = SKIFF_MOUNTPOINT;
const char *init_pid_path = SKIFF_INIT_PID;
static pid_t target_pid = 0;

static struct namespace_file {
  int nstype;
  const char *name;
  int fd;
} namespace_files[] = {
    {.nstype = CLONE_NEWIPC, .name = "ns/ipc", .fd = -1},
    {.nstype = CLONE_NEWUTS, .name = "ns/uts", .fd = -1},
    {.nstype = CLONE_NEWNET, .name = "ns/net", .fd = -1},
    {.nstype = CLONE_NEWPID, .name = "ns/pid", .fd = -1},
    {.nstype = CLONE_NEWNS, .name = "ns/mnt", .fd = -1},
    {.nstype = 0, .name = NULL, .fd = -1}};

void continue_as_child(void);
int open_target_fd(int *fd, const char *type);
int check_pid_exists(pid_t pid);

int main(int argc, char *argv[]) {
  int res = 0;
  struct stat st = {0};

  // disable logging buffering
  logfd = stderr;
  setbuf(logfd, NULL);

  // maintain our uid
  uid_t uid = getuid();

  // starting work dir
  char* startingWd = get_current_dir_name();
  if (stat(startingWd, &st) != 0) {
    free(startingWd);
    startingWd = strdup("/");
  }

  // step 1: wait for PID file for the target to appear without doing anything.
  usleep(200 * 1000); // 200ms delay for pid file to be deleted on start
  for (int i = 0; i < INIT_WAIT_PID_MAX / WAIT_PID_POLL_DUR; i++) {
    if (stat(init_pid_path, &st) == 0) {
      break;
    }
    usleep(WAIT_PID_POLL_DUR * 1000);
  }

  // step 2: find PID file, check PID exists
  // find the PID file for the target
  // possibly loop several times
  int attempts = 0;
  do {
    if (attempts++ >= WAIT_PID_MAX_ATTEMPTS) {
      fprintf(logfd, "SkiffOS: failed to nsenter, run 'wsl.exe --shutdown' and try again.\n");
      return res;
    }

    // if pid file already exists
    if (stat(init_pid_path, &st) == 0) {
      // read pid
      FILE *pidf;
      int pidi = 0;
      if (!(pidf = fopen(init_pid_path, "r"))) {
        res = errno;
        if (res != ENOENT) {
          fprintf(logfd, "SkiffOS: could not read init pid: %s: (%d) %s\n",
                  init_pid_path, res, strerror(res));
          return res;
        } else {
          res = 0; // ignore not found
        }
      } else { // file opened
        int sres = fscanf(pidf, "%d", &pidi);
        fclose(pidf);
        if (sres == 0 || pidi < 1) {
          fprintf(logfd, "SkiffOS: could not read init pid: %s: file empty\n",
                  init_pid_path);
          return 1;
        }
        if (pidi > 0) {
          target_pid = pidi;
        }
      }
    }

    if (target_pid != 0) {
      // confirm that the target pid is still active
      if (check_pid_exists(target_pid) != 0) {
        break;
      }
      target_pid = 0;
    }

    // wait for pid file (basic polling implementation)
    int didStart = 0;
    for (int i = 0; i < WAIT_PID_MAX / WAIT_PID_POLL_DUR; i++) {
      usleep(WAIT_PID_POLL_DUR * 1000);
      if (stat(init_pid_path, &st) == 0) {
        didStart = 1;
        break;
      }
    }
    if (!didStart) {
      fprintf(logfd, "SkiffOS: timed out waiting for init process to start\n");
    }
  } while (target_pid == 0);

  // We have the target pid, let's change namespace into it.
  int namespaces = 0;
  struct namespace_file *nsfile;
  for (nsfile = namespace_files; nsfile->nstype; nsfile++) {
    namespaces |= nsfile->nstype;
    if (nsfile->fd >= 0) {
      continue;
    }
    res = open_target_fd(&nsfile->fd, nsfile->name);
    if (res == 0 && nsfile->fd < 0) {
      res = 1;
    }
    if (res != 0) {
      return res;
    }
  }
  for (nsfile = namespace_files; nsfile->nstype; nsfile++) {
    if (setns(nsfile->fd, nsfile->nstype) != 0) {
      res = errno;
      fprintf(logfd, "SkiffOS: failed to setns to %d at %s: (%d) %s\n",
              target_pid, nsfile->name, res, strerror(res));
      return res;
    }
    close(nsfile->fd);
    nsfile->fd = -1;
  }

  // Attempt to chroot into target dir
#ifndef NO_CHROOT_TARGET
  chdir(mountpoint);
  if (chroot(mountpoint) != 0) {
    res = errno;
    fprintf(logfd,
            "SkiffOS: failed to chroot to target after nsenter: (%d) %s\n", res,
            strerror(res));
    return res;
  }
  chdir("/");
#endif

  // cd to target dir (if set)
#ifndef NO_RESTORE_PWD
  if (stat(startingWd, &st) == 0) {
    chdir(startingWd);
  }
#endif

  // determine user shell from /etc/passwd
  struct passwd *pw = getpwuid(uid);
  if (pw == NULL) {
    res = errno;
    fprintf(logfd,
            "SkiffOS: failed to determine user (%d) shell in chroot: (%d) %s\n",
            uid, res, strerror(res));
    return res;
  }
  char *userShell;
  if (pw->pw_shell != NULL && strlen(pw->pw_shell) != 0) {
    userShell = strdup(pw->pw_shell);
  } else {
    userShell = strdup(DEFAULT_SHELL);
  }

  // if argv[0] starts with -, prepend a - to the shell.
  char* userShellArgv0 = userShell;
  if (argc > 0 && argv[0] != NULL && strlen(argv[0]) && argv[0][0] == '-') {
    int userShellLen = strlen(userShell);
    userShellArgv0 = (char *)malloc((userShellLen * sizeof(char)) + (2 * sizeof(char *)));
    userShellArgv0[0] = '-';
    char* userShellBn = basename(userShell);
    int userShellBnLen = strlen(userShellBn);
    memcpy(userShellArgv0 + 1, userShellBn, userShellBnLen);
    userShellArgv0[userShellBnLen] = 0;
  }

  // copy arguments from parent shell
  if (argc < 1) {
    argc = 1;
  }
  char **shellargv = (char **)malloc((argc + 1) * sizeof(char *));
  shellargv[argc] = NULL;
  shellargv[0] = userShellArgv0;
  for (int i = 1; i < argc; i++) { // skip argv[0]
    size_t len = strlen(argv[i]) + 1;
    shellargv[i] = malloc(len * sizeof(char));
    memcpy(shellargv[i], argv[i], len);
  }

  // we must fork() before calling execve() to have children inherit the PID namespace.
  continue_as_child();

  // drop environment
  char** shellenv = NULL;
#ifdef NO_DROP_ENV
  shellenv = environ;
#endif
  if (execve(userShell, shellargv, environ) != 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: failed to exec shell process: (%d) %s\n", res, strerror(res));
    return res;
  }

  if (userShellArgv0 && userShellArgv0 != userShell) {
    free(userShellArgv0);
  }
  free(userShell);
  free(shellargv);
  free(startingWd);
  return 0;
}

int open_target_fd(int *fd, const char *type) {
  char pathbuf[PATH_MAX];

  if (!target_pid) {
    return 1;
  }

  snprintf(pathbuf, sizeof(pathbuf), "/proc/%u/%s", target_pid, type);

  int res = 0;
  if (*fd >= 0)
    close(*fd);
  *fd = open(pathbuf, O_RDONLY);
  if (*fd < 0) {
    res = errno;
    fprintf(logfd,
            "SkiffOS: could not open namespace file for pid %d: %s: (%d) %s\n",
            target_pid, pathbuf, res, strerror(res));
    *fd = -1;
  }
  return res;
}

int check_pid_exists(pid_t pid) {
  struct stat st = {0};
  char pathbuf[PATH_MAX];
  if (!pid) {
    return 0;
  }

  snprintf(pathbuf, sizeof(pathbuf), "/proc/%u", pid);
  if (stat(pathbuf, &st) == 0) {
    return 1;
  }
  return 0;
}

void continue_as_child(void) {
  pid_t child = fork();
  int status;
  pid_t ret;
  int res;

  if (child < 0) {
    res = errno;
    fprintf(logfd, "SkiffOS: unable to fork: (%d) %s\n", res, strerror(res));
    exit(res);
  }

  /* Only the child returns */
  if (child == 0)
    return;

  for (;;) {
    ret = waitpid(child, &status, WUNTRACED);
    if ((ret == child) && (WIFSTOPPED(status))) {
      /* The child suspended so suspend us as well */
      kill(getpid(), SIGSTOP);
      kill(child, SIGCONT);
    } else {
      break;
    }
  }
  /* Return the child's exit code if possible */
  if (WIFEXITED(status)) {
    exit(WEXITSTATUS(status));
  } else if (WIFSIGNALED(status)) {
    kill(getpid(), WTERMSIG(status));
  }
  exit(1);
}
