LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := pvrsrvinit.lu5400
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := pvrsrvinit.c
LOCAL_SHARED_LIBRARIES := libdl liblog
LOCAL_CFLAGS := -Wall -Wextra -Werror
include $(BUILD_EXECUTABLE)
