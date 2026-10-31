# Included by the shared-library hook after the platform selects this module.
ifneq ($(filter OMXNodeInstance.cpp,$(LOCAL_SRC_FILES)),OMXNodeInstance.cpp)
$(error LU5400 OMX fixup: platform source list changed; review node teardown)
endif

lu5400_omx_source := $(LOCAL_PATH)/OMXNodeInstance.cpp
lu5400_omx_fixup := device/lge/lu5400/omx/fixup_free_node.py
lu5400_omx_generated := $(call intermediates-dir-for,SHARED_LIBRARIES,libstagefright_omx)/lu5400_OMXNodeInstance.cpp

LOCAL_SRC_FILES := $(filter-out OMXNodeInstance.cpp,$(LOCAL_SRC_FILES))
LOCAL_GENERATED_SOURCES += $(lu5400_omx_generated)

$(lu5400_omx_generated): PRIVATE_LU5400_OMX_FIXUP := $(lu5400_omx_fixup)
$(lu5400_omx_generated): $(lu5400_omx_source) $(lu5400_omx_fixup) device/lge/lu5400/omx/module.mk
	@echo "LU5400 OMX teardown fixup: $@"
	$(hide) mkdir -p $(dir $@)
	$(hide) python $(PRIVATE_LU5400_OMX_FIXUP) $< $@
