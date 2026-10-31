LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := libcorkscrew
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_PATH := $(TARGET_OUT)/vendor/lib
LOCAL_SRC_FILES := corkscrew.c
include $(BUILD_SHARED_LIBRARY)
