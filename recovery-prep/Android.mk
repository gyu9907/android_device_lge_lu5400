LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := prepare-recovery.lu5400
LOCAL_SRC_FILES := prepare-recovery.c
LOCAL_MODULE_TAGS := optional
LOCAL_CFLAGS := -Wall -Wextra -Werror
include $(BUILD_EXECUTABLE)
