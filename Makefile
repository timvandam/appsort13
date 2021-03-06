export SDKVERSION = 13.5

ARCHS = arm64 arm64e

THEOS_DEVICE_IP = 192.168.0.102

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = appsort13

appsort13_FILES = AlertWindow.x IconImageProcessing.x Tweak.x
appsort13_CFLAGS = -fobjc-arc
appsort13_LIBRARIES = activator
appsort13_FRAMEWORKS = AudioToolbox UIKit CoreImage

include $(THEOS_MAKE_PATH)/tweak.mk

after-stage::
	$(ECHO_NOTHING)cp -r Library/ $(THEOS_STAGING_DIR)/$(ECHO_END)
