LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := rild
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := rild.c
LOCAL_C_INCLUDES := hardware/ril/include
LOCAL_SHARED_LIBRARIES := liblog libcutils libril libdl
LOCAL_CFLAGS := -DRIL_SHLIB
LOCAL_CLANG := false
include $(BUILD_EXECUTABLE)
