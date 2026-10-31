LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_PRELINK_MODULE := false
LOCAL_ARM_MODE := arm
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/../vendor/lib/hw
LOCAL_SHARED_LIBRARIES := liblog libEGL libcutils libutils libhardware libhardware_legacy libz \
                          libion_ti

# Use the device-local CM11 OMAP4/LG implementation. It implements
# HWC 1.0 and sync fences with TI DDK 1.9 gralloc and LG DSSCOMP.
LOCAL_SRC_FILES := \
    hwc.c \
    rgz_2d.c \
    dock_image.c \
    sw_vsync.c \
    edid/lib/edid_parser.c
LOCAL_STATIC_LIBRARIES := libpng

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE := hwcomposer.lu5400
LOCAL_CFLAGS := -DLOG_TAG=\"ti_hwc\"
LOCAL_C_INCLUDES += \
    external/libpng \
    external/zlib \
    $(LOCAL_PATH) \
    $(LOCAL_PATH)/include \
    $(LOCAL_PATH)/edid \
    $(LOCAL_PATH)/edid/inc \
    $(LOCAL_PATH)/../include

ifeq ($(BOARD_USE_SYSFS_VSYNC_NOTIFICATION),true)
LOCAL_CFLAGS += -DSYSFS_VSYNC_NOTIFICATION
endif

# LOG_NDEBUG=0 means verbose logging enabled
# LOCAL_CFLAGS += -DLOG_NDEBUG=0
include $(BUILD_SHARED_LIBRARY)
