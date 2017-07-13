DEBUG = 0

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:9.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:latest:9.0
endif

PACKAGE_VERSION = 1.5.1

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Emoji10PS
Emoji10PS_FILES = Tweak.xm
Emoji10PS_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/tweak.mk

ifeq ($(SIMULATOR),1)
all::
	@rm -f /opt/simject/$(TWEAK_NAME).dylib
	@cp -v $(THEOS_OBJ_DIR)/$(TWEAK_NAME).dylib /opt/simject
	@cp -v $(PWD)/$(TWEAK_NAME).plist /opt/simject
endif
