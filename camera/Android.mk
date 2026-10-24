LOCAL_PATH := $(call my-dir)

# The ICS camera uses jhead symbols but names libexif.so as its dependency.
# Keep the compatibility library separate from the platform libexif. The short
# name fits in the blob's existing DT_NEEDED string without moving ELF data.
include $(CLEAR_VARS)
LOCAL_MODULE := libjex
LOCAL_MODULE_TAGS := optional
LOCAL_C_INCLUDES := $(LOCAL_PATH)/jhead
LOCAL_SRC_FILES := \
    jhead/exif.c \
    jhead/gpsinfo.c \
    jhead/iptc.c \
    jhead/jhead.c \
    jhead/jpgfile.c \
    jhead/makernote.c
LOCAL_SHARED_LIBRARIES := liblog
LOCAL_CFLAGS := -fcommon
include $(BUILD_SHARED_LIBRARY)

lu5400_camera_blob := vendor/lge/lu5400/proprietary/lib/hw/camera.omap4.so
lu5400_camera_fixup := $(LOCAL_PATH)/fixup_camera.py
lu5400_camera_manifest := $(LOCAL_PATH)/../proprietary-files.txt
lu5400_camera_fixed := $(call intermediates-dir-for,SHARED_LIBRARIES,camera.lu5400)/fixed/camera.lu5400.so

$(lu5400_camera_fixed): PRIVATE_FIXUP := $(lu5400_camera_fixup)
$(lu5400_camera_fixed): PRIVATE_MANIFEST := $(lu5400_camera_manifest)
$(lu5400_camera_fixed): $(lu5400_camera_blob) $(lu5400_camera_fixup) $(lu5400_camera_manifest)
	@echo "LU5400 camera EXIF fixup: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) python $(PRIVATE_FIXUP) $< $@ $(PRIVATE_MANIFEST)

include $(CLEAR_VARS)
LOCAL_MODULE := camera.lu5400
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_MODULE_PATH := $(TARGET_OUT_SHARED_LIBRARIES)/hw
LOCAL_PREBUILT_MODULE_FILE := $(lu5400_camera_fixed)
LOCAL_STRIP_MODULE := false
LOCAL_REQUIRED_MODULES := libjex
include $(BUILD_PREBUILT)
