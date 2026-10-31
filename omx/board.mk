# Preserve any previously registered shared-library hook.
$(eval lu5400_previous_shared_library_hook = $(value target-shared-library-hook))

define target-shared-library-hook
$(call lu5400_previous_shared_library_hook)
$(if $(filter lu5400,$(TARGET_DEVICE)),$(if $(filter libstagefright_omx,$(LOCAL_MODULE)),$(eval include device/lge/lu5400/omx/module.mk)))
endef
