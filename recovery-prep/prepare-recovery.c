/* LU5400 stock bootloader requires a misc command before reboot recovery. */
#include <errno.h>
#include <fcntl.h>
#include <stdio.h>
#include <string.h>
#include <sys/stat.h>
#include <unistd.h>

#define MISC_DEVICE "/dev/block/platform/omap/omap_hsmmc.1/by-name/misc"

static int prepare_recovery(const char *path)
{
    const char command[32] = "boot-recovery";
    char verify[sizeof(command)];
    struct stat st;
    int fd = open(path, O_RDWR | O_CLOEXEC);
    if (fd < 0)
        goto fail;
    if (fstat(fd, &st) < 0)
        goto close_fail;
    if (!S_ISBLK(st.st_mode)) {
        errno = ENODEV;
        goto close_fail;
    }
    /* Only the command field: preserve status, recovery arguments and NV data. */
    if (pwrite(fd, command, sizeof(command), 0) != sizeof(command))
        goto close_fail;
    if (fsync(fd) < 0)
        goto close_fail;
    if (pread(fd, verify, sizeof(verify), 0) != sizeof(verify))
        goto close_fail;
    if (memcmp(command, verify, sizeof(command))) {
        errno = EIO;
        goto close_fail;
    }
    if (close(fd) < 0)
        goto fail;
    return 0;

close_fail:
    {
        int saved_errno = errno ? errno : EIO;
        close(fd);
        errno = saved_errno;
    }
fail:
    fprintf(stderr, "LU5400 recovery preparation failed: %s\n", strerror(errno));
    return 1;
}

int main(int argc, char **argv)
{
    /* android_reboot appends its target; never arm recovery for other targets. */
    if (argc != 2 || strcmp(argv[1], "recovery"))
        return 0;
    return prepare_recovery(MISC_DEVICE);
}
