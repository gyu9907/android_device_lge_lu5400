LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_PRELINK_MODULE := false
LOCAL_ARM_MODE := arm
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/../vendor/lib/hw
LOCAL_SHARED_LIBRARIES := liblog libEGL libcutils libutils libhardware libhardware_legacy libz \
                          libion_ti

# Use the CM11 OMAP4/LG implementation maintained by P920.  It implements
# HWC 1.0 and sync fences while retaining the LG omap_hwc_data Post2 ABI.
P920_HWC_PATH := ../../p920/hwc
LOCAL_SRC_FILES := \
    $(P920_HWC_PATH)/hwc.c \
    $(P920_HWC_PATH)/rgz_2d.c \
    $(P920_HWC_PATH)/dock_image.c \
    $(P920_HWC_PATH)/sw_vsync.c \
    ../../p920/edid/lib/edid_parser.c
LOCAL_STATIC_LIBRARIES := libpng

LOCAL_MODULE_TAGS := optional

LOCAL_MODULE := hwcomposer.lu5400
LOCAL_CFLAGS := -DLOG_TAG=\"ti_hwc\" -DLGE_LU5400_GRALLOC_ABI
LOCAL_C_INCLUDES += \
    external/libpng \
    external/zlib \
    $(LOCAL_PATH)/$(P920_HWC_PATH) \
    $(LOCAL_PATH)/../../p920/include \
    $(LOCAL_PATH)/../../p920/edid \
    $(LOCAL_PATH)/../../p920/edid/inc \
    $(LOCAL_PATH)/../include

ifeq ($(BOARD_USE_SYSFS_VSYNC_NOTIFICATION),true)
LOCAL_CFLAGS += -DSYSFS_VSYNC_NOTIFICATION
endif

# LOG_NDEBUG=0 means verbose logging enabled
# LOCAL_CFLAGS += -DLOG_NDEBUG=0
include $(BUILD_SHARED_LIBRARY)
