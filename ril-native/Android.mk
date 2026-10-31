# Copyright 2006 The Android Open Source Project
# Licensed under the Apache License, Version 2.0; see NOTICE.
LOCAL_PATH := $(call my-dir)
include $(CLEAR_VARS)
LOCAL_MODULE := libril
LOCAL_MODULE_TAGS := optional
LOCAL_SRC_FILES := ril.cpp ril_event.cpp
LOCAL_C_INCLUDES := $(LOCAL_PATH) hardware/ril/include
LOCAL_SHARED_LIBRARIES := liblog libutils libbinder libcutils libhardware_legacy librilutils
include $(BUILD_SHARED_LIBRARY)
