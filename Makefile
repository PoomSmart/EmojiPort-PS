PACKAGE_VERSION = 1.5.7

ifeq ($(SIMULATOR),1)
	TARGET = simulator:clang:latest:9.0
	ARCHS = x86_64 i386
else
	TARGET = iphone:clang:latest:9.0
endif

include $(THEOS)/makefiles/common.mk

LIBRARY_NAME = Emoji10PSReal
Emoji10PSReal_FILES = TweakReal.xm
Emoji10PSReal_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries/Emoji10PS
Emoji10PSReal_EXTRA_FRAMEWORKS = CydiaSubstrate
Emoji10PSReal_LIBRARIES = EmojiLibrary
Emoji10PSReal_USE_SUBSTRATE = 1

include $(THEOS_MAKE_PATH)/library.mk

ifneq ($(SIMULATOR),1)
TWEAK_NAME = Emoji10PS
Emoji10PS_FILES = Tweak.xm

include $(THEOS_MAKE_PATH)/tweak.mk
endif

ifeq ($(SIMULATOR),1)
setup:: clean all
	@rm -f /opt/simject/Emoji10PS.dylib
	@cp -v $(THEOS_OBJ_DIR)/$(LIBRARY_NAME).dylib /opt/simject/Emoji10PS.dylib
	@cp -v $(PWD)/Emoji10PS.plist /opt/simject
endif
