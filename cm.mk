## Specify phone tech before including full_phone
$(call inherit-product, vendor/cm/config/gsm.mk)

# Release name
PRODUCT_RELEASE_NAME := LU5400

# Boot animation
TARGET_BOOTANIMATION_NAME := vertical-480x800
TARGET_SCREEN_WIDTH := 480
TARGET_SCREEN_HEIGHT := 800

# Inherit some common CM stuff.
$(call inherit-product, vendor/cm/config/common_full_phone.mk)

# Enhanced NFC
$(call inherit-product, vendor/cm/config/nfc_enhanced.mk)

# Inherit device configuration
$(call inherit-product, device/lge/lu5400/full_lu5400.mk)

## Device identifier. This must come after all inclusions
PRODUCT_DEVICE := lu5400
PRODUCT_NAME := cm_lu5400
PRODUCT_BRAND := lge
PRODUCT_MODEL := LG-LU5400
PRODUCT_MANUFACTURER := LGE

#Set build fingerprint / ID / Product Name ect.
PRODUCT_BUILD_PROP_OVERRIDES += PRODUCT_NAME=lu5400 BUILD_FINGERPRINT="lge/lu5400/lu5400:4.2.2/IMM76D/47E63EA8:user/release-keys" PRIVATE_BUILD_DESC="lu5400-user 4.2.2 IMM76D 47E63EA5 release-keys"
