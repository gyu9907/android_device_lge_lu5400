LOCAL_PATH := $(call my-dir)

lu5400_lge_ril_fixed := $(call intermediates-dir-for,SHARED_LIBRARIES,lge-ril)/fixed/lge-ril.so
$(lu5400_lge_ril_fixed): PRIVATE_FIXUP := $(LOCAL_PATH)/fixup_ril.py
$(lu5400_lge_ril_fixed): vendor/lge/lu5400/proprietary/lib/lge-ril.so $(LOCAL_PATH)/fixup_ril.py
	@echo "LU540141 CRT PIC fixup: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) python $(PRIVATE_FIXUP) $< $@
include $(CLEAR_VARS)
LOCAL_MODULE := lge-ril
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_PREBUILT_MODULE_FILE := $(lu5400_lge_ril_fixed)
LOCAL_STRIP_MODULE := false
include $(BUILD_PREBUILT)

lu5400_libini_fixed := $(call intermediates-dir-for,SHARED_LIBRARIES,libini)/fixed/libini.so
$(lu5400_libini_fixed): PRIVATE_FIXUP := $(LOCAL_PATH)/fixup_ril.py
$(lu5400_libini_fixed): vendor/lge/lu5400/proprietary/lib/libini.so $(LOCAL_PATH)/fixup_ril.py
	@echo "LU540141 CRT PIC fixup: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) python $(PRIVATE_FIXUP) $< $@
include $(CLEAR_VARS)
LOCAL_MODULE := libini
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_PREBUILT_MODULE_FILE := $(lu5400_libini_fixed)
LOCAL_STRIP_MODULE := false
include $(BUILD_PREBUILT)

lu5400_libhdcp_fixed := $(call intermediates-dir-for,SHARED_LIBRARIES,libhdcp)/fixed/libhdcp.so
$(lu5400_libhdcp_fixed): PRIVATE_FIXUP := $(LOCAL_PATH)/fixup_ril.py
$(lu5400_libhdcp_fixed): vendor/lge/lu5400/proprietary/lib/libhdcp.so $(LOCAL_PATH)/fixup_ril.py
	@echo "LU540141 CRT PIC fixup: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) python $(PRIVATE_FIXUP) $< $@
include $(CLEAR_VARS)
LOCAL_MODULE := libhdcp
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_PREBUILT_MODULE_FILE := $(lu5400_libhdcp_fixed)
LOCAL_STRIP_MODULE := false
include $(BUILD_PREBUILT)

lu5400_gps_omap4_fixed := $(call intermediates-dir-for,SHARED_LIBRARIES,gps.omap4)/fixed/gps.omap4.so
$(lu5400_gps_omap4_fixed): PRIVATE_FIXUP := $(LOCAL_PATH)/fixup_ril.py
$(lu5400_gps_omap4_fixed): vendor/lge/lu5400/proprietary/lib/hw/gps.omap4.so $(LOCAL_PATH)/fixup_ril.py
	@echo "LU540141 CRT PIC fixup: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) python $(PRIVATE_FIXUP) $< $@
include $(CLEAR_VARS)
LOCAL_MODULE := gps.omap4
LOCAL_MODULE_TAGS := optional
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_PREBUILT_MODULE_FILE := $(lu5400_gps_omap4_fixed)
LOCAL_STRIP_MODULE := false
LOCAL_MODULE_RELATIVE_PATH := hw
include $(BUILD_PREBUILT)

include device/lge/lu5400/ril-compat/native/Android.mk
include device/lge/lu5400/ril-compat/rild/Android.mk
include hardware/ril/librilutils/Android.mk
