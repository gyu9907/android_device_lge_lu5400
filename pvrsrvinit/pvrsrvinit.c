/* Based on Motorola omap4-common a2afd02: initialize SGX from a PIE binary.
 * Keep the LU5400 SGX540_120 userspace ABI and proprietary libraries.
 * Like LG's original launcher, load modules in the pvrsrvinit domain, which
 * owns CAP_SYS_MODULE. Kernel 3.0 requires init_module, not finit_module. */
#define LOG_TAG "pvrsrvinit.lu5400"
#include <cutils/log.h>
#include <dlfcn.h>
#include <errno.h>
#include <fcntl.h>
#include <stdlib.h>
#include <string.h>
#include <sys/mman.h>
#include <sys/stat.h>
#include <sys/syscall.h>
#include <unistd.h>

static int load_module(const char *path)
{
    struct stat st;
    int fd = open(path, O_RDONLY | O_CLOEXEC);
    if (fd < 0) {
        ALOGE("open %s: %s", path, strerror(errno));
        return -1;
    }
    if (fstat(fd, &st) < 0 || st.st_size <= 0) {
        ALOGE("Cannot read module size: %s", path);
        close(fd);
        return -1;
    }
    void *image = mmap(NULL, st.st_size, PROT_READ, MAP_PRIVATE, fd, 0);
    close(fd);
    if (image == MAP_FAILED) {
        ALOGE("mmap %s: %s", path, strerror(errno));
        return -1;
    }
    int result = syscall(SYS_init_module, image, (unsigned long)st.st_size, "");
    int error = errno;
    munmap(image, st.st_size);
    if (result < 0 && error != EEXIST) {
        ALOGE("init_module %s: %s", path, strerror(error));
        return -1;
    }
    ALOGI("Module ready: %s", path);
    return 0;
}

static int wait_for_gpu(void)
{
    struct stat st;
    /* ueventd creates and labels the node asynchronously after module init. */
    int tries;
    for (tries = 0; tries < 100; ++tries) {
        if (stat("/dev/pvrsrvkm", &st) == 0 && S_ISCHR(st.st_mode))
            return 0;
        usleep(50000);
    }
    ALOGE("Timed out waiting for /dev/pvrsrvkm");
    return -1;
}

int main(void)
{
    if (load_module("/system/modules/pvrsrvkm_sgx540_120.ko") < 0 ||
        load_module("/system/modules/omaplfb_sgx540_120.ko") < 0 ||
        wait_for_gpu() < 0)
        return EXIT_FAILURE;

    void *lib = dlopen("/system/vendor/lib/libsrv_init_SGX540_120.so", RTLD_NOW);
    if (!lib) {
        ALOGE("dlopen: %s", dlerror());
        return EXIT_FAILURE;
    }
    int (*srv_init)(int) = (int (*)(int))dlsym(lib, "SrvInit");
    if (!srv_init) {
        ALOGE("dlsym SrvInit: %s", dlerror());
        dlclose(lib);
        return EXIT_FAILURE;
    }
    int result = srv_init(1);
    ALOGI("SrvInit returned %d", result);
    dlclose(lib);
    return result == 0 ? EXIT_SUCCESS : EXIT_FAILURE;
}
